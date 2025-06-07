use dojo_starter::model::game_model::{
    GameMode, GameBalance, Game, GameTrait, GameCounter, GameStatus,
};
use dojo_starter::model::player_model::{
    Player, PlayerSymbol, UsernameToAddress, AddressToUsername, PlayerTrait,
};
use dojo_starter::interfaces::IWorld::IWorld;

// dojo decorator
#[dojo::contract]
pub mod world {
    use super::{
        IWorld, Player, GameMode, GameBalance, PlayerSymbol, Game, GameTrait, UsernameToAddress,
        AddressToUsername, PlayerTrait, GameCounter, GameStatus,
    };
    use dojo_starter::model::property_model::{Property, PropertyTrait, PropertyToId, IdToProperty};
    use core::array::Array;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const,
        get_contract_address,
    };


    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use origami_random::dice::{Dice, DiceTrait};


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub username: felt252,
        #[key]
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerJoined {
        #[key]
        pub game_id: u256,
        #[key]
        pub username: felt252,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PropertyPurchased {
        #[key]
        pub game_id: u256,
        #[key]
        pub property_id: u8,
        pub buyer: ContractAddress,
        pub seller: ContractAddress,
        pub amount: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PropertyMortgaged {
        #[key]
        pub game_id: u256,
        #[key]
        pub property_id: u8,
        pub owner: ContractAddress,
        pub amount_received: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PropertyUnmortgaged {
        #[key]
        pub game_id: u256,
        #[key]
        pub property_id: u8,
        pub owner: ContractAddress,
        pub amount_paid: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct RentCollected {
        #[key]
        pub game_id: u256,
        #[key]
        pub property_id: u8,
        pub from_player: ContractAddress,
        pub to_player: ContractAddress,
        pub amount: u256,
        pub development_level: u8,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PropertyDeveloped {
        #[key]
        pub game_id: u256,
        #[key]
        pub property_id: u8,
        pub owner: ContractAddress,
        pub development_level: u8,
        pub cost: u256,
        pub timestamp: u64,
    }


    #[abi(embed_v0)]
    impl WorldImpl of IWorld<ContractState> {
        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }
        fn register_new_player(
            ref self: ContractState,
            username: felt252,
            is_bot: bool,
            player_symbol: PlayerSymbol,
            initial_balance: u256,
        ) {
            assert(!is_bot, 'Bot detected');
            let mut world = self.world_default();

            let caller: ContractAddress = get_caller_address();

            let zero_address: ContractAddress = contract_address_const::<0x0>();

            // Validate username
            assert(username != 0, 'USERNAME CANNOT BE ZERO');

            // Check if the player already exists (ensure username is unique)
            let existing_player: UsernameToAddress = world.read_model(username);
            assert(existing_player.address == zero_address, 'USERNAME ALREADY TAKEN');

            // Ensure player cannot update username by calling this function
            let existing_username = self.get_username_from_address(caller);

            assert(existing_username == 0, 'USERNAME ALREADY CREATED');

            let new_player: Player = PlayerTrait::new(
                username, caller, is_bot, player_symbol, initial_balance,
            );
            let username_to_address: UsernameToAddress = UsernameToAddress {
                username, address: caller,
            };
            let address_to_username: AddressToUsername = AddressToUsername {
                address: caller, username,
            };

            world.write_model(@new_player);
            world.write_model(@username_to_address);
            world.write_model(@address_to_username);
            world
                .emit_event(
                    @PlayerCreated { username, player: caller, timestamp: get_block_timestamp() },
                );
        }

        fn create_new_game_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val.try_into().unwrap()
        }

        fn get_players_balance(
            ref self: ContractState, player: ContractAddress, game_id: u256,
        ) -> u256 {
            let world = self.world_default();

            let players_balance: GameBalance = world.read_model((player, game_id));
            players_balance.balance
        }

        fn get_properties_owned_by_player(
            ref self: ContractState, player: ContractAddress, game_id: u256,
        ) -> Array<u8> {
            let world = self.world_default();
            let mut owned_properties = ArrayTrait::new();

            // Check all 40 properties (standard Monopoly board)
            let mut property_id: u8 = 1;
            loop {
                if property_id > 40 {
                    break;
                }

                let property: Property = world.read_model((property_id, game_id));
                if property.owner == player {
                    owned_properties.append(property_id);
                }

                property_id += 1;
            };

            owned_properties
        }

        fn get_properties_by_group(
            ref self: ContractState, group_id: u8, game_id: u256,
        ) -> Array<u8> {
            let world = self.world_default();
            let mut group_properties = ArrayTrait::new();

            // Check all 40 properties
            let mut property_id: u8 = 1;
            loop {
                if property_id > 40 {
                    break;
                }

                let property: Property = world.read_model((property_id, game_id));
                if property.group_id == group_id {
                    group_properties.append(property_id);
                }

                property_id += 1;
            };

            group_properties
        }

        fn has_monopoly(
            ref self: ContractState, player: ContractAddress, group_id: u8, game_id: u256,
        ) -> bool {
            let world = self.world_default();
            let group_properties = self.get_properties_by_group(group_id, game_id);

            // Check if player owns all properties in the group
            let mut i = 0;
            loop {
                if i >= group_properties.len() {
                    break true;
                }

                let property_id = *group_properties.at(i);
                let property: Property = world.read_model((property_id, game_id));

                if property.owner != player {
                    break false;
                }

                i += 1;
            }
        }

        fn collect_rent_with_monopoly(
            ref self: ContractState, property_id: u8, game_id: u256,
        ) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let property: Property = world.read_model((property_id, game_id));
            let zero_address: ContractAddress = contract_address_const::<0>();

            assert(property.owner != zero_address, 'Property is unowned');
            assert(property.owner != caller, 'You cannot pay rent to yourself');
            assert(property.is_mortgaged == false, 'No rent on mortgaged properties');

            let mut rent_amount: u256 = match property.development {
                0 => property.rent_site_only,
                1 => property.rent_one_house,
                2 => property.rent_two_houses,
                3 => property.rent_three_houses,
                4 => property.rent_four_houses,
                5 => property.rent_hotel,
                _ => panic!("Invalid development level"),
            };

            // Apply monopoly bonus (double rent if no houses)
            if property.development == 0
                && self.has_monopoly(property.owner, property.group_id, game_id) {
                rent_amount *= 2;
            }

            self.transfer_from(caller, property.owner, game_id, rent_amount);

            // Emit RentCollected event
            world
                .emit_event(
                    @RentCollected {
                        game_id,
                        property_id,
                        from_player: caller,
                        to_player: property.owner,
                        amount: rent_amount,
                        development_level: property.development,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }

        fn get_property_value(ref self: ContractState, property_id: u8, game_id: u256) -> u256 {
            let world = self.world_default();
            let property: Property = world.read_model((property_id, game_id));

            if property.is_mortgaged {
                // Mortgaged property value = property cost + development cost - mortgage debt
                let mortgage_debt = property.cost_of_property / 2;
                let interest = mortgage_debt * 10 / 100;
                let total_debt = mortgage_debt + interest;
                let development_value = property.development.into() * property.cost_of_house;

                if property.cost_of_property + development_value > total_debt {
                    property.cost_of_property + development_value - total_debt
                } else {
                    0
                }
            } else {
                // Unmortgaged property value = property cost + development cost
                property.cost_of_property + (property.development.into() * property.cost_of_house)
            }
        }

        fn can_develop_evenly(
            ref self: ContractState,
            property_id: u8,
            group_id: u8,
            game_id: u256,
            is_building: bool // true for building, false for selling
        ) -> bool {
            let world = self.world_default();
            let current_property: Property = world.read_model((property_id, game_id));
            let group_properties = self.get_properties_by_group(group_id, game_id);

            let mut i = 0;
            loop {
                if i >= group_properties.len() {
                    break true;
                }

                let other_property_id = *group_properties.at(i);
                if other_property_id != property_id {
                    let other_property: Property = world.read_model((other_property_id, game_id));

                    if is_building {
                        // When building: current property cannot have more houses than any other
                        // property in the group (must build evenly)
                        if current_property.development > other_property.development {
                            break false;
                        }
                    } else {
                        // When selling: current property cannot have fewer houses than any other
                        // property in the group after selling (current_development - 1)
                        if current_property.development < other_property.development {
                            break false;
                        }
                    }
                }

                i += 1;
            }
        }

        fn can_develop_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let world = self.world_default();
            let property: Property = world.read_model((property_id, game_id));
            let caller = get_caller_address();

            // Check basic requirements
            if property.owner != caller || property.is_mortgaged || property.development >= 5 {
                return false;
            }

            // Check if player has monopoly
            if !self.has_monopoly(caller, property.group_id, game_id) {
                return false;
            }

            // (must build evenly across all properties in group)
            self.can_develop_evenly(property_id, property.group_id, game_id, true)
        }

        fn can_sell_development(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let world = self.world_default();
            let property: Property = world.read_model((property_id, game_id));
            let caller = get_caller_address();

            // Check basic requirements
            if property.owner != caller || property.development == 0 {
                return false;
            }

            // Check even development rule for selling
            // (must sell evenly across all properties in group)
            self.can_develop_evenly(property_id, property.group_id, game_id, false)
        }

        fn batch_generate_properties(
            ref self: ContractState,
            game_id: u256,
            properties: Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>,
        ) {
            let mut world = self.world_default();
            let mut i = 0;

            loop {
                if i >= properties.len() {
                    break;
                }

                let (
                    id,
                    name,
                    cost,
                    rent_site,
                    rent_1h,
                    rent_2h,
                    rent_3h,
                    rent_4h,
                    cost_house,
                    rent_hotel,
                    group_id,
                ) =
                    *properties
                    .at(i);

                self
                    .generate_properties(
                        id,
                        game_id,
                        name,
                        cost,
                        rent_site,
                        rent_1h,
                        rent_2h,
                        rent_3h,
                        rent_4h,
                        cost_house,
                        rent_hotel,
                        false,
                        group_id,
                    );

                i += 1;
            };
        }

        fn create_new_game(
            ref self: ContractState,
            game_mode: GameMode,
            player_symbol: PlayerSymbol,
            number_of_players: u8,
        ) -> u256 {
            // Get default world
            let mut world = self.world_default();

            assert(number_of_players >= 2 && number_of_players <= 8, 'invalid no of players');

            // Get the account address of the caller
            let caller_address = get_caller_address();
            let caller_username = self.get_username_from_address(caller_address);
            assert(caller_username != 0, 'PLAYER NOT REGISTERED');

            let game_id = self.create_new_game_id();
            let timestamp = get_block_timestamp();

            let player_hat = match player_symbol {
                PlayerSymbol::Hat => caller_username,
                _ => 0,
            };

            let player_car = match player_symbol {
                PlayerSymbol::Car => caller_username,
                _ => 0,
            };
            let player_dog = match player_symbol {
                PlayerSymbol::Dog => caller_username,
                _ => 0,
            };
            let player_thimble = match player_symbol {
                PlayerSymbol::Thimble => caller_username,
                _ => 0,
            };
            let player_iron = match player_symbol {
                PlayerSymbol::Iron => caller_username,
                _ => 0,
            };
            let player_battleship = match player_symbol {
                PlayerSymbol::Battleship => caller_username,
                _ => 0,
            };
            let player_boot = match player_symbol {
                PlayerSymbol::Boot => caller_username,
                _ => 0,
            };
            let player_wheelbarrow = match player_symbol {
                PlayerSymbol::Wheelbarrow => caller_username,
                _ => 0,
            };

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                game_id,
                caller_username,
                game_mode,
                player_hat,
                player_car,
                player_dog,
                player_thimble,
                player_iron,
                player_battleship,
                player_boot,
                player_wheelbarrow,
                number_of_players,
            );

            // If it's a multiplayer game, set status to Pending,
            // else mark it as Ongoing (for single-player).
            if game_mode == GameMode::MultiPlayer {
                new_game.status = GameStatus::Pending;
            } else {
                new_game.status = GameStatus::Ongoing;
            }

            world.write_model(@new_game);

            world.emit_event(@GameCreated { game_id, timestamp });

            game_id
        }


        fn retrieve_player(ref self: ContractState, addr: ContractAddress) -> Player {
            // Get default world
            let mut world = self.world_default();
            let player: Player = world.read_model(addr);

            player
        }

        fn retrieve_game(ref self: ContractState, game_id: u256) -> Game {
            // Get default world
            let mut world = self.world_default();
            //get the game state
            let game: Game = world.read_model(game_id);
            game
        }

        fn generate_properties(
            ref self: ContractState,
            id: u8,
            game_id: u256,
            name: felt252,
            cost_of_property: u256,
            rent_site_only: u256,
            rent_one_house: u256,
            rent_two_houses: u256,
            rent_three_houses: u256,
            rent_four_houses: u256,
            cost_of_house: u256,
            rent_hotel: u256,
            is_mortgaged: bool,
            group_id: u8,
        ) {
            let mut world = self.world_default();
            let mut property: Property = world.read_model((id, game_id));

            property =
                PropertyTrait::new(
                    id,
                    game_id,
                    name,
                    cost_of_property,
                    rent_site_only,
                    rent_one_house,
                    rent_two_houses,
                    rent_three_houses,
                    rent_four_houses,
                    cost_of_house,
                    rent_hotel,
                    group_id,
                );

            let property_to_id: PropertyToId = PropertyToId { name, id };
            let id_to_property: IdToProperty = IdToProperty { id, name };

            world.write_model(@property);
            world.write_model(@property_to_id);
            world.write_model(@id_to_property);
        }

        fn get_property(ref self: ContractState, id: u8, game_id: u256) -> Property {
            let mut world = self.world_default();
            let property = world.read_model((id, game_id));
            property
        }
        fn sell_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Can only sell your property');

            property.for_sale = true;
            world.write_model(@property);

            true
        }

        fn buy_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();
            let zero_address: ContractAddress = contract_address_const::<0>();
            let amount: u256 = property.cost_of_property;

            // Validate property can be purchased
            assert(property.id != 0, 'Property does not exist');

            if property.owner == zero_address {
                // Buying from bank
                self.transfer_from(caller, contract_address, game_id, amount);
            } else {
                // Buying from another player
                assert(property.owner != caller, 'Cannot buy your own property');
                assert(property.for_sale, 'Property is not for sale');
                self.transfer_from(caller, property.owner, game_id, amount);
            }

            property.owner = caller;
            property.for_sale = false;

            world.write_model(@property);

            // Emit property purchase event
            let seller = if property.owner == zero_address {
                get_contract_address()
            } else {
                property.owner
            };

            // Emit PropertyPurchased event
            world
                .emit_event(
                    @PropertyPurchased {
                        game_id,
                        property_id,
                        buyer: caller,
                        seller,
                        amount,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }
        fn mortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Only the owner can mortgage ');
            assert(property.is_mortgaged == false, 'Property is already mortgaged');

            let amount: u256 = property.cost_of_property / 2;
            let contract_address = get_contract_address();

            self.transfer_from(contract_address, caller, game_id, amount);

            property.is_mortgaged = true;
            world.write_model(@property);

            // Emit PropertyMortgaged event
            world
                .emit_event(
                    @PropertyMortgaged {
                        game_id,
                        property_id,
                        owner: caller,
                        amount_received: amount,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }

        fn unmortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Only the owner can unmortgage');
            assert(property.is_mortgaged, 'Property is not mortgaged');

            let mortgage_amount: u256 = property.cost_of_property / 2;
            let interest: u256 = mortgage_amount * 10 / 100; // 10% interest
            let repay_amount: u256 = mortgage_amount + interest;

            self.transfer_from(caller, get_contract_address(), game_id, repay_amount);

            property.is_mortgaged = false;
            world.write_model(@property);

            // Emit PropertyUnmortgaged event
            world
                .emit_event(
                    @PropertyUnmortgaged {
                        game_id,
                        property_id,
                        owner: caller,
                        amount_paid: repay_amount,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }

        fn collect_rent(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let property: Property = world.read_model((property_id, game_id));
            let zero_address: ContractAddress = contract_address_const::<0>();

            assert(property.owner != zero_address, 'Property is unowned');
            assert(property.owner != caller, 'You cannot pay rent to yourself');
            assert(property.is_mortgaged == false, 'No rent on mortgaged properties');

            let rent_amount: u256 = match property.development {
                0 => property.rent_site_only,
                1 => property.rent_one_house,
                2 => property.rent_two_houses,
                3 => property.rent_three_houses,
                4 => property.rent_four_houses,
                5 => property.rent_hotel,
                _ => panic!("Invalid development level"),
            };

            self.transfer_from(caller, property.owner, game_id, rent_amount);

            // Emit RentCollected event
            world
                .emit_event(
                    @RentCollected {
                        game_id,
                        property_id,
                        from_player: caller,
                        to_player: property.owner,
                        amount: rent_amount,
                        development_level: property.development,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }


        fn transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            game_id: u256,
            amount: u256,
        ) {
            let mut world = self.world_default();

            let mut sender: GameBalance = world.read_model((from, game_id));
            let mut recepient: GameBalance = world.read_model((to, game_id));
            assert(sender.balance >= amount, 'insufficient funds');
            sender.balance -= amount;
            recepient.balance += amount;
            world.write_model(@sender);
            world.write_model(@recepient);
        }

        fn buy_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(self.can_develop_property(property_id, game_id), 'Cannot develop property');

            let cost: u256 = property.cost_of_house;
            self.transfer_from(caller, contract_address, game_id, cost);

            property.development += 1; // Increases to 5 (hotel) max

            world.write_model(@property);

            // Emit PropertyDeveloped event
            world
                .emit_event(
                    @PropertyDeveloped {
                        game_id,
                        property_id,
                        owner: caller,
                        development_level: property.development,
                        cost,
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }

        fn sell_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(self.can_sell_development(property_id, game_id), 'Cannot sell development');

            let refund: u256 = property.cost_of_house / 2;

            self.transfer_from(contract_address, caller, game_id, refund);

            property.development -= 1;

            world.write_model(@property);

            // Emit PropertyDeveloped event (development level decreased)
            world
                .emit_event(
                    @PropertyDeveloped {
                        game_id,
                        property_id,
                        owner: caller,
                        development_level: property.development,
                        cost: refund, // negative cost (refund)
                        timestamp: get_block_timestamp(),
                    },
                );

            true
        }

        fn mint(ref self: ContractState, recepient: ContractAddress, game_id: u256, amount: u256) {
            let mut world = self.world_default();

            let mut receiver: GameBalance = world.read_model((recepient, game_id));
            let balance = receiver.balance + amount;
            receiver.balance = balance;
            world.write_model(@receiver);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"blockopoly")
        }
    }
}
