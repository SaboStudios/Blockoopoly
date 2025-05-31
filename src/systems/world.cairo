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
        pub game_id: u64,
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
        pub game_id: u64,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerJoined {
        #[key]
        pub game_id: u64,
        #[key]
        pub username: felt252,
        pub timestamp: u64,
    }


    #[abi(embed_v0)]
    impl WorldImpl of IWorld<ContractState> {
        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }
        fn register_new_player(ref self: ContractState, username: felt252, is_bot: bool) {
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

            let new_player: Player = PlayerTrait::new(username, caller, is_bot);
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

        fn create_new_game_id(ref self: ContractState) -> u64 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }

        fn get_players_balance(
            ref self: ContractState, player: ContractAddress, game_id: u256,
        ) -> u256 {
            let world = self.world_default();

            let players_balance: GameBalance = world.read_model((player, game_id));
            players_balance.balance
        }

        fn create_new_game(
            ref self: ContractState,
            game_mode: GameMode,
            player_symbol: PlayerSymbol,
            number_of_players: u8,
        ) -> u64 {
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

        fn retrieve_game(ref self: ContractState, game_id: u64) -> Game {
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
                    rent_hotel,
                    cost_of_house,
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

            if property.owner == zero_address {
                self.transfer_from(caller, contract_address, game_id, amount);
            } else {
                assert(property.for_sale == true, 'Property is not for sale');
                self.transfer_from(caller, property.owner, game_id, amount);
            }

            property.owner = caller;
            property.for_sale = false;

            world.write_model(@property);
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

            true
        }

        fn unmortgage_property(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));

            assert(property.owner == caller, 'Only the owner can unmortgage');
            assert(property.is_mortgaged == true, 'Property is not mortgaged');

            let mortgage_amount: u256 = property.cost_of_property / 2;
            let interest: u256 = mortgage_amount * 10 / 100; // 10% interest
            let repay_amount: u256 = mortgage_amount + interest;

            self.transfer_from(caller, get_contract_address(), game_id, repay_amount);

            property.is_mortgaged = false;
            world.write_model(@property);

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

            assert(property.owner == caller, 'Only the owner ');
            assert(property.is_mortgaged == false, 'Cannot develop');
            assert(property.development < 5, 'Maximum development ');

            let cost: u256 = property.cost_of_house;
            self.transfer_from(caller, contract_address, game_id, cost);

            property.development += 1; // Increases to 5 (hotel) max

            world.write_model(@property);

            true
        }

        fn sell_house_or_hotel(ref self: ContractState, property_id: u8, game_id: u256) -> bool {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut property: Property = world.read_model((property_id, game_id));
            let contract_address = get_contract_address();

            assert(property.owner == caller, 'Only the owner ');
            assert(property.development > 0, 'No houses to sell');

            let refund: u256 = property.cost_of_house / 2;

            self.transfer_from(contract_address, caller, game_id, refund);

            property.development -= 1;

            world.write_model(@property);

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
