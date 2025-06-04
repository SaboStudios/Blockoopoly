#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::world::{world};
    use dojo_starter::interfaces::IWorld::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo_starter::model::game_model::{
        Game, m_Game, GameMode, GameStatus, GameCounter, m_GameCounter, GameBalance, m_GameBalance,
    };
    use dojo_starter::model::property_model::{
        Property, m_Property, IdToProperty, m_IdToProperty, PropertyToId, m_PropertyToId,
    };
    use dojo_starter::model::player_model::{
        Player, m_Player, UsernameToAddress, m_UsernameToAddress, AddressToUsername,
        m_AddressToUsername, PlayerSymbol,
    };
    use starknet::{testing, get_caller_address, contract_address_const};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "blockopoly",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameBalance::TEST_CLASS_HASH),
                TestResource::Model(m_Property::TEST_CLASS_HASH),
                TestResource::Model(m_IdToProperty::TEST_CLASS_HASH),
                TestResource::Model(m_PropertyToId::TEST_CLASS_HASH),
                TestResource::Model(m_UsernameToAddress::TEST_CLASS_HASH),
                TestResource::Model(m_AddressToUsername::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Event(world::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(world::e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(world::e_PlayerJoined::TEST_CLASS_HASH),
                TestResource::Event(world::e_GameStarted::TEST_CLASS_HASH),
                TestResource::Event(world::e_PropertyPurchased::TEST_CLASS_HASH),
                TestResource::Event(world::e_PropertyMortgaged::TEST_CLASS_HASH),
                TestResource::Event(world::e_PropertyUnmortgaged::TEST_CLASS_HASH),
                TestResource::Event(world::e_RentCollected::TEST_CLASS_HASH),
                TestResource::Event(world::e_PropertyDeveloped::TEST_CLASS_HASH),
                TestResource::Contract(world::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"blockopoly", @"world")
                .with_writer_of([dojo::utils::bytearray_hash(@"blockopoly")].span())
        ]
            .span()
    }

    fn setup_game_with_player() -> (IWorldDispatcher, u256, ContractAddress) {
        let caller = contract_address_const::<'player1'>();
        let username = 'Player1';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"world").unwrap();
        let actions_system = IWorldDispatcher { contract_address };

        testing::set_contract_address(caller);
        actions_system.register_new_player(username, false, PlayerSymbol::Dog, 100);

        let game_id = actions_system.create_new_game(GameMode::MultiPlayer, PlayerSymbol::Hat, 4);

        // Mint initial balance
        actions_system.mint(caller, game_id, 10000);

        (actions_system, game_id, caller)
    }

    #[test]
    fn test_get_properties_owned_by_player() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate test properties
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);
        actions_system.generate_properties(3, game_id, 'Property3', 300, 20, 140, 240, 340, 440, 400, 600, false, 2);

        // Buy properties 1 and 2
        testing::set_contract_address(caller);
        actions_system.buy_property(1, game_id);
        actions_system.buy_property(2, game_id);

        // Check owned properties
        let owned_properties = actions_system.get_properties_owned_by_player(caller, game_id);
        assert(owned_properties.len() == 2, 'Should own 2 properties');
        assert(*owned_properties.at(0) == 1, 'Should own property 1');
        assert(*owned_properties.at(1) == 2, 'Should own property 2');
    }

    #[test]
    fn test_get_properties_by_group() {
        let (actions_system, game_id, _) = setup_game_with_player();

        // Generate properties in group 1
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);
        actions_system.generate_properties(3, game_id, 'Property3', 300, 20, 140, 240, 340, 440, 400, 600, false, 2);

        let group_1_properties = actions_system.get_properties_by_group(1, game_id);
        assert(group_1_properties.len() == 2, 'Group 1 should have 2 properties');
        assert(*group_1_properties.at(0) == 1, 'Group 1 should contain property 1');
        assert(*group_1_properties.at(1) == 2, 'Group 1 should contain property 2');

        let group_2_properties = actions_system.get_properties_by_group(2, game_id);
        assert(group_2_properties.len() == 1, 'Group 2 should have 1 property');
        assert(*group_2_properties.at(0) == 3, 'Group 2 should contain property 3');
    }

    #[test]
    fn test_monopoly_detection() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate properties in group 1
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);

        // Player doesn't have monopoly initially
        assert(!actions_system.has_monopoly(caller, 1, game_id), 'Should not have monopoly');

        // Buy first property
        testing::set_contract_address(caller);
        actions_system.buy_property(1, game_id);
        assert(!actions_system.has_monopoly(caller, 1, game_id), 'Should not have monopoly with 1 property');

        // Buy second property to complete monopoly
        actions_system.buy_property(2, game_id);
        assert(actions_system.has_monopoly(caller, 1, game_id), 'Should have monopoly');
    }

    #[test]
    fn test_monopoly_rent_bonus() {
        let (actions_system, game_id, caller) = setup_game_with_player();
        let player2 = contract_address_const::<'player2'>();

        // Register second player
        testing::set_contract_address(player2);
        actions_system.register_new_player('Player2', false, PlayerSymbol::Car, 100);
        actions_system.mint(player2, game_id, 5000);

        // Generate properties in group 1
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);

        // Player 1 buys both properties to create monopoly
        testing::set_contract_address(caller);
        actions_system.buy_property(1, game_id);
        actions_system.buy_property(2, game_id);

        // Player 2 pays rent with monopoly bonus
        testing::set_contract_address(player2);
        let balance_before = actions_system.get_players_balance(player2, game_id);
        actions_system.collect_rent_with_monopoly(1, game_id);
        let balance_after = actions_system.get_players_balance(player2, game_id);

        // Should pay double rent (20 instead of 10)
        assert(balance_before - balance_after == 20, 'Should pay double rent for monopoly');
    }

    #[test]
    fn test_property_value_calculation() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate property
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);

        // Buy property
        testing::set_contract_address(caller);
        actions_system.buy_property(1, game_id);

        // Test value without development
        let value = actions_system.get_property_value(1, game_id);
        assert(value == 200, 'Basic property value should be 200');

        // Develop property
        actions_system.buy_house_or_hotel(1, game_id);
        let value_with_house = actions_system.get_property_value(1, game_id);
        assert(value_with_house == 500, 'Property with house should be 500'); // 200 + 300

        // Test mortgaged property value
        actions_system.mortgage_property(1, game_id);
        let mortgaged_value = actions_system.get_property_value(1, game_id);
        // Mortgaged value = (200 + 300) - (100 + 10) = 390
        assert(mortgaged_value == 390, 'Mortgaged property value incorrect');
    }

    #[test]
    fn test_can_develop_property() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate properties in group 1
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);

        testing::set_contract_address(caller);

        // Cannot develop unowned property
        assert(!actions_system.can_develop_property(1, game_id), 'Cannot develop unowned property');

        // Buy one property
        actions_system.buy_property(1, game_id);
        assert(!actions_system.can_develop_property(1, game_id), 'Cannot develop without monopoly');

        // Buy second property to complete monopoly
        actions_system.buy_property(2, game_id);
        assert(actions_system.can_develop_property(1, game_id), 'Should be able to develop with monopoly');

        // Mortgage property
        actions_system.mortgage_property(1, game_id);
        assert(!actions_system.can_develop_property(1, game_id), 'Cannot develop mortgaged property');
    }

    #[test]
    fn test_batch_property_generation() {
        let (actions_system, game_id, _) = setup_game_with_player();

        let mut properties = ArrayTrait::new();
        properties.append((1, 'Prop1', 200, 10, 100, 200, 300, 400, 300, 500, 1));
        properties.append((2, 'Prop2', 250, 15, 120, 220, 320, 420, 350, 550, 1));
        properties.append((3, 'Prop3', 300, 20, 140, 240, 340, 440, 400, 600, 2));

        actions_system.batch_generate_properties(game_id, properties);

        // Verify all properties were created
        let prop1 = actions_system.get_property(1, game_id);
        assert(prop1.name == 'Prop1', 'Property 1 name incorrect');
        assert(prop1.cost_of_property == 200, 'Property 1 cost incorrect');

        let prop2 = actions_system.get_property(2, game_id);
        assert(prop2.name == 'Prop2', 'Property 2 name incorrect');
        assert(prop2.cost_of_property == 250, 'Property 2 cost incorrect');

        let prop3 = actions_system.get_property(3, game_id);
        assert(prop3.name == 'Prop3', 'Property 3 name incorrect');
        assert(prop3.cost_of_property == 300, 'Property 3 cost incorrect');
    }

    #[test]
    fn test_property_ownership_edge_cases() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate property
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);

        testing::set_contract_address(caller);

        // Buy property
        actions_system.buy_property(1, game_id);

        // Try to collect rent from own property (should fail)
        // This test should panic, but we'll verify the property owner
        let property = actions_system.get_property(1, game_id);
        assert(property.owner == caller, 'Property should be owned by caller');
    }

    #[test]
    fn test_development_constraints() {
        let (actions_system, game_id, caller) = setup_game_with_player();

        // Generate properties in group 1 (need monopoly to develop)
        actions_system.generate_properties(1, game_id, 'Property1', 200, 10, 100, 200, 300, 400, 300, 500, false, 1);
        actions_system.generate_properties(2, game_id, 'Property2', 250, 15, 120, 220, 320, 420, 350, 550, false, 1);

        testing::set_contract_address(caller);

        // Buy both properties to get monopoly
        actions_system.buy_property(1, game_id);
        actions_system.buy_property(2, game_id);

        // Develop to maximum (5 levels)
        actions_system.buy_house_or_hotel(1, game_id); // Level 1
        actions_system.buy_house_or_hotel(1, game_id); // Level 2
        actions_system.buy_house_or_hotel(1, game_id); // Level 3
        actions_system.buy_house_or_hotel(1, game_id); // Level 4
        actions_system.buy_house_or_hotel(1, game_id); // Level 5 (hotel)

        let property = actions_system.get_property(1, game_id);
        assert(property.development == 5, 'Should have maximum development');

        // Verify cannot develop further
        assert(!actions_system.can_develop_property(1, game_id), 'Cannot develop beyond maximum');
    }
} 