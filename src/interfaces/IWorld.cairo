use dojo_starter::model::game_model::{GameMode, Game};
use dojo_starter::model::player_model::{PlayerSymbol, Player};

use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IWorld<T> {
    fn register_new_player(ref self: T, username: felt252, is_bot: bool);
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn retrieve_player(ref self: T, addr: ContractAddress) -> Player;
    fn create_new_game(
        ref self: T, game_mode: GameMode, player_symbol: PlayerSymbol, number_of_players: u8,
    ) -> u64;
    fn create_new_game_id(ref self: T) -> u64;
    fn retrieve_game(ref self: T, game_id: u64) -> Game;
}
