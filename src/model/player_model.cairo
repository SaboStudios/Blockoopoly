use starknet::{ContractAddress, contract_address_const};

pub fn zero_address() -> ContractAddress {
    contract_address_const::<0>()
}

// #[derive(Copy, Drop, Serde, Debug)]
#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub username: felt252,
    pub is_bot: bool,
    pub new_owner: ContractAddress,
    pub balance: u256,
    pub position: u8,
    pub jailed: bool,
    pub player_symbol: PlayerSymbol,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
}


pub trait PlayerTrait {
    // Create a new player
    // `username` - Username to assign to the new player
    // `owner` - Account owner of player
    // returns the created player
    fn new(
        username: felt252,
        player: ContractAddress,
        is_bot: bool,
        player_symbol: PlayerSymbol,
        initial_balance: u256,
    ) -> Player;
    fn move_player(ref self: Player, steps: u8, board_size: u8);
    fn pay_rent_to(ref self: Player, ref recipient: Player, amount: u256) -> bool;
    fn buy_property(ref self: Player, ref seller: Player, amount: u256) -> bool;
    fn update_stats(ref self: Player, played: u256, completed: u256, won: u256);
    fn set_jail_status(ref self: Player, jailed: bool);
    fn transfer_ownership(ref self: Player, new_owner: ContractAddress);
    fn collect_go_money(ref self: Player, amount: u256);
    fn pay_fee(ref self: Player, amount: u256) -> bool;
    fn can_afford(self: @Player, amount: u256) -> bool;
    fn is_bankrupt(self: @Player) -> bool;
    fn get_win_rate(self: @Player) -> u256;
}

pub impl PlayerImpl of PlayerTrait {
    fn new(
        username: felt252,
        player: ContractAddress,
        is_bot: bool,
        player_symbol: PlayerSymbol,
        initial_balance: u256,
    ) -> Player {
        Player {
            player,
            username,
            is_bot,
            new_owner: zero_address(),
            balance: initial_balance,
            position: 0,
            jailed: false,
            player_symbol,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,
        }
    }

    fn move_player(ref self: Player, steps: u8, board_size: u8) {
        assert(board_size > 0, 'Board not greater than 0');

        let old_position = self.position;
        let total_steps = old_position + steps;
        let new_position = total_steps % board_size;

        let laps = total_steps / board_size;
        self.balance += 200_u256 * laps.into();

        self.position = new_position;
    }
    fn pay_rent_to(ref self: Player, ref recipient: Player, amount: u256) -> bool {
        if !self.can_afford(amount) {
            return false;
        }

        if self.player == recipient.player {
            return false;
        }

        if amount == 0 {
            return false;
        }

        self.balance -= amount;
        recipient.balance += amount;

        true
    }

    fn buy_property(ref self: Player, ref seller: Player, amount: u256) -> bool {
        if !self.can_afford(amount) {
            return false;
        }

        if self.player == seller.player {
            return false;
        }

        if amount == 0 {
            return false;
        }

        self.balance -= amount;
        seller.balance += amount;

        true
    }

    fn update_stats(ref self: Player, played: u256, completed: u256, won: u256) {
        self.total_games_played += played;
        self.total_games_completed += completed;
        self.total_games_won += won;
    }

    fn set_jail_status(ref self: Player, jailed: bool) {
        self.jailed = jailed;
        if jailed {
            self.position = 10;
        }
    }

    fn transfer_ownership(ref self: Player, new_owner: ContractAddress) {
        self.new_owner = new_owner;
    }

    fn collect_go_money(ref self: Player, amount: u256) {
        self.balance += amount;
    }

    fn pay_fee(ref self: Player, amount: u256) -> bool {
        if !self.can_afford(amount) {
            return false;
        }

        self.balance -= amount;
        true
    }

    fn can_afford(self: @Player, amount: u256) -> bool {
        *self.balance >= amount
    }

    fn is_bankrupt(self: @Player) -> bool {
        *self.balance == 0
    }

    fn get_win_rate(self: @Player) -> u256 {
        if *self.total_games_completed == 0 {
            return 0;
        }
        (*self.total_games_won * 100) / *self.total_games_completed
    }
}

pub trait PlayerSymbolTrait {
    fn is_valid(symbol: PlayerSymbol) -> bool;
    fn get_name(symbol: PlayerSymbol) -> felt252;
    fn from_felt(value: felt252) -> Option<PlayerSymbol>;
}

pub impl PlayerSymbolImpl of PlayerSymbolTrait {
    fn is_valid(symbol: PlayerSymbol) -> bool {
        match symbol {
            PlayerSymbol::Hat => true,
            PlayerSymbol::Car => true,
            PlayerSymbol::Dog => true,
            PlayerSymbol::Thimble => true,
            PlayerSymbol::Iron => true,
            PlayerSymbol::Battleship => true,
            PlayerSymbol::Boot => true,
            PlayerSymbol::Wheelbarrow => true,
        }
    }

    fn get_name(symbol: PlayerSymbol) -> felt252 {
        match symbol {
            PlayerSymbol::Hat => 'Hat',
            PlayerSymbol::Car => 'Car',
            PlayerSymbol::Dog => 'Dog',
            PlayerSymbol::Thimble => 'Thimble',
            PlayerSymbol::Iron => 'Iron',
            PlayerSymbol::Battleship => 'Battleship',
            PlayerSymbol::Boot => 'Boot',
            PlayerSymbol::Wheelbarrow => 'Wheelbarrow',
        }
    }

    fn from_felt(value: felt252) -> Option<PlayerSymbol> {
        if value == 'Hat' {
            Option::Some(PlayerSymbol::Hat)
        } else if value == 'Car' {
            Option::Some(PlayerSymbol::Car)
        } else if value == 'Dog' {
            Option::Some(PlayerSymbol::Dog)
        } else if value == 'Thimble' {
            Option::Some(PlayerSymbol::Thimble)
        } else if value == 'Iron' {
            Option::Some(PlayerSymbol::Iron)
        } else if value == 'Battleship' {
            Option::Some(PlayerSymbol::Battleship)
        } else if value == 'Boot' {
            Option::Some(PlayerSymbol::Boot)
        } else if value == 'Wheelbarrow' {
            Option::Some(PlayerSymbol::Wheelbarrow)
        } else {
            Option::None
        }
    }
}


pub trait PlayerValidation {
    fn validate_creation(
        username: felt252,
        player: ContractAddress,
        player_symbol: PlayerSymbol,
        initial_balance: u256,
    ) -> bool;

    fn validate_transaction(payer: @Player, recipient: @Player, amount: u256) -> bool;

    fn validate_username(username: felt252) -> bool;
}

pub impl PlayerValidationImpl of PlayerValidation {
    fn validate_creation(
        username: felt252,
        player: ContractAddress,
        player_symbol: PlayerSymbol,
        initial_balance: u256,
    ) -> bool {
        if player == zero_address() {
            return false;
        }

        if username == 0 {
            return false;
        }

        if !PlayerSymbolImpl::is_valid(player_symbol) {
            return false;
        }

        true
    }

    fn validate_transaction(payer: @Player, recipient: @Player, amount: u256) -> bool {
        if !payer.can_afford(amount) {
            return false;
        }

        if *payer.player == *recipient.player {
            return false;
        }

        if amount == 0 {
            return false;
        }

        true
    }

    fn validate_username(username: felt252) -> bool {
        username != 0
    }
}

pub trait PlayerActions {
    fn go_to_jail(ref self: Player);
    fn get_out_of_jail(ref self: Player, pay_fee: bool, fee_amount: u256) -> bool;
    fn pass_go(ref self: Player, go_amount: u256);
    fn pay_tax(ref self: Player, tax_amount: u256) -> bool;
    fn receive_money(ref self: Player, amount: u256);
    fn reset_position(ref self: Player);
}

pub impl PlayerActionsImpl of PlayerActions {
    fn go_to_jail(ref self: Player) {
        self.jailed = true;
        self.position = 10;
    }

    fn get_out_of_jail(ref self: Player, pay_fee: bool, fee_amount: u256) -> bool {
        if pay_fee {
            if !self.can_afford(fee_amount) {
                return false;
            }
            self.balance -= fee_amount;
        }

        self.jailed = false;
        true
    }

    fn pass_go(ref self: Player, go_amount: u256) {
        self.balance += go_amount;
    }

    fn pay_tax(ref self: Player, tax_amount: u256) -> bool {
        if !self.can_afford(tax_amount) {
            return false;
        }

        self.balance -= tax_amount;
        true
    }

    fn receive_money(ref self: Player, amount: u256) {
        self.balance += amount;
    }

    fn reset_position(ref self: Player) {
        self.position = 0;
        self.jailed = false;
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum PlayerSymbol {
    Hat,
    Car,
    Dog,
    Thimble,
    Iron,
    Battleship,
    Boot,
    Wheelbarrow,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UsernameToAddress {
    #[key]
    pub username: felt252,
    pub address: ContractAddress,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct AddressToUsername {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
}
