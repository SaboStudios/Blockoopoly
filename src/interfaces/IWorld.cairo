use dojo_starter::model::game_model::{GameMode, Game};
use dojo_starter::model::player_model::{PlayerSymbol, Player};
use dojo_starter::model::property_model::{Property};

use starknet::{ContractAddress};

// define the interface
#[starknet::interface]
pub trait IWorld<T> {
    fn register_new_player(
        ref self: T,
        username: felt252,
        is_bot: bool,
        player_symbol: PlayerSymbol,
        initial_balance: u256,
    );
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn retrieve_player(ref self: T, addr: ContractAddress) -> Player;
    fn create_new_game(
        ref self: T, game_mode: GameMode, player_symbol: PlayerSymbol, number_of_players: u8,
    ) -> u256;
    fn create_new_game_id(ref self: T) -> u256;
    fn retrieve_game(ref self: T, game_id: u256) -> Game;
    fn generate_properties(
        ref self: T,
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
    );
    fn get_property(ref self: T, id: u8, game_id: u256) -> Property;
    fn buy_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn mortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn unmortgage_property(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn collect_rent(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn transfer_from(
        ref self: T, from: ContractAddress, to: ContractAddress, game_id: u256, amount: u256,
    );
    fn buy_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn sell_house_or_hotel(ref self: T, property_id: u8, game_id: u256) -> bool;
    fn mint(ref self: T, recepient: ContractAddress, game_id: u256, amount: u256);
    fn get_players_balance(ref self: T, player: ContractAddress, game_id: u256) -> u256;
    
    fn get_properties_owned_by_player(
        ref self: T, player: ContractAddress, game_id: u256,
    ) -> Array<u8>;
    fn get_properties_by_group(
        ref self: T, group_id: u8, game_id: u256,
    ) -> Array<u8>;
    fn has_monopoly(
        ref self: T, 
        player: ContractAddress, 
        group_id: u8, 
        game_id: u256,
    ) -> bool;
    fn collect_rent_with_monopoly(
        ref self: T, 
        property_id: u8, 
        game_id: u256,
    ) -> bool;
    fn get_property_value(
        ref self: T, 
        property_id: u8, 
        game_id: u256,
    ) -> u256;
    fn can_develop_property(
        ref self: T,
        property_id: u8,
        game_id: u256,
    ) -> bool;
    fn batch_generate_properties(
        ref self: T,
        game_id: u256,
        properties: Array<(u8, felt252, u256, u256, u256, u256, u256, u256, u256, u256, u8)>,
    );
}
