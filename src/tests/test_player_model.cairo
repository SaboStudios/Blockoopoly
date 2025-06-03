use dojo_starter::model::player_model::{
    Player, PlayerTrait, PlayerImpl, PlayerSymbol, PlayerSymbolTrait, PlayerSymbolImpl,
    PlayerValidation, PlayerValidationImpl, PlayerActions, PlayerActionsImpl, zero_address,
};

use starknet::{ContractAddress, contract_address_const};


fn create_test_player() -> Player {
    PlayerImpl::new(
        'TestPlayer', contract_address_const::<0x123>(), false, PlayerSymbol::Hat, 1500_u256,
    )
}

fn create_test_bot() -> Player {
    PlayerImpl::new(
        'TestBot', contract_address_const::<0x456>(), true, PlayerSymbol::Car, 1500_u256,
    )
}

#[test]
fn test_player_creation() {
    let player = create_test_player();

    assert(player.username == 'TestPlayer', 'Wrong username');
    assert(player.player == contract_address_const::<0x123>(), 'Wrong address');
    assert(!player.is_bot, 'Should not be bot');
    assert(player.balance == 1500_u256, 'Wrong initial balance');
    assert(player.position == 0, 'Wrong initial position');
    assert(!player.jailed, 'Should not be jailed');
    assert(player.player_symbol == PlayerSymbol::Hat, 'Wrong symbol');
    assert(player.total_games_played == 0, 'Wrong games played');
    assert(player.total_games_completed == 0, 'Wrong games completed');
    assert(player.total_games_won == 0, 'Wrong games won');
    assert(player.new_owner == zero_address(), 'Wrong new owner');
}

#[test]
fn test_bot_creation() {
    let bot = create_test_bot();

    assert(bot.is_bot, 'Should be bot');
    assert(bot.player_symbol == PlayerSymbol::Car, 'Wrong bot symbol');
}

#[test]
fn test_move_player_normal() {
    let mut player = create_test_player();
    let initial_balance = player.balance;

    player.move_player(5, 40);

    assert(player.position == 5, 'Wrong position after move');
    assert(player.balance == initial_balance, 'Balance should not change');
}

#[test]
fn test_move_player_pass_go() {
    let mut player = create_test_player();
    player.position = 38;
    let initial_balance = player.balance;

    player.move_player(5, 40);

    assert(player.position == 3, 'Wrong position after passing go');
    assert(player.balance == initial_balance + 200, 'Should receive go money');
}

#[test]
fn test_move_player_multiple_laps() {
    let mut player = create_test_player();
    let initial_balance = player.balance;

    player.move_player(85, 40);

    assert(player.position == 5, 'Wrong position');
    assert(player.balance == initial_balance + 400, 'Should receive money for 2 laps');
}

#[test]
#[should_panic(expected: ('Board not greater than 0',))]
fn test_move_player_zero_board_size() {
    let mut player = create_test_player();
    player.move_player(5, 0);
}

#[test]
fn test_pay_rent_successful() {
    let mut payer = create_test_player();
    let mut recipient = create_test_bot();
    let rent_amount = 100_u256;
    let payer_initial = payer.balance;
    let recipient_initial = recipient.balance;

    let result = payer.pay_rent_to(ref recipient, rent_amount);

    assert(result, 'Rent payment should succeed');
    assert(payer.balance == payer_initial - rent_amount, 'Payer balance wrong');
    assert(recipient.balance == recipient_initial + rent_amount, 'Recipient balance wrong');
}

#[test]
fn test_pay_rent_insufficient_funds() {
    let mut payer = create_test_player();
    let mut recipient = create_test_bot();
    let rent_amount = 2000_u256;

    let result = payer.pay_rent_to(ref recipient, rent_amount);

    assert(!result, 'Rent payment should fail');
}

#[test]
fn test_pay_rent_to_self() {
    let mut player = create_test_player();
    let mut player_copy = create_test_player();

    let result = player.pay_rent_to(ref player_copy, 100_u256);

    assert(!result, 'Should not pay rent to self');
}

#[test]
fn test_pay_rent_zero_amount() {
    let mut payer = create_test_player();
    let mut recipient = create_test_bot();

    let result = payer.pay_rent_to(ref recipient, 0_u256);

    assert(!result, 'Should not pay zero rent');
}

#[test]
fn test_buy_property_successful() {
    let mut buyer = create_test_player();
    let mut seller = create_test_bot();
    let price = 200_u256;
    let buyer_initial = buyer.balance;
    let seller_initial = seller.balance;

    let result = buyer.buy_property(ref seller, price);

    assert(result, 'Should succeed');
    assert(buyer.balance == buyer_initial - price, 'Buyer balance wrong');
    assert(seller.balance == seller_initial + price, 'Seller balance wrong');
}

#[test]
fn test_buy_property_insufficient_funds() {
    let mut buyer = create_test_player();
    let mut seller = create_test_bot();
    let price = 2000_u256;

    let result = buyer.buy_property(ref seller, price);

    assert(!result, 'Property purchase should fail');
}

#[test]
fn test_update_stats() {
    let mut player = create_test_player();

    player.update_stats(1, 1, 0);
    assert(player.total_games_played == 1, 'Wrong games played');
    assert(player.total_games_completed == 1, 'Wrong games completed');
    assert(player.total_games_won == 0, 'Wrong games won');

    player.update_stats(2, 1, 1);
    assert(player.total_games_played == 3, 'Wrong cumulative games played');
    assert(player.total_games_completed == 2, 'Wrong cumulative games');
    assert(player.total_games_won == 1, 'Wrong cumulative games won');
}

#[test]
fn test_jail_status() {
    let mut player = create_test_player();

    player.set_jail_status(true);
    assert(player.jailed, 'Should be jailed');
    assert(player.position == 10, 'Should be at jail position');

    player.set_jail_status(false);
    assert(!player.jailed, 'Should not be jailed');
    assert(player.position == 10, 'Position should remain at jail');
}

#[test]
fn test_transfer_ownership() {
    let mut player = create_test_player();
    let new_owner = contract_address_const::<0x789>();

    player.transfer_ownership(new_owner);
    assert(player.new_owner == new_owner, 'Wrong new owner');
}

#[test]
fn test_collect_go_money() {
    let mut player = create_test_player();
    let initial_balance = player.balance;
    let go_amount = 200_u256;

    player.collect_go_money(go_amount);
    assert(player.balance == initial_balance + go_amount, 'Wrong balance after go');
}

#[test]
fn test_pay_fee_successful() {
    let mut player = create_test_player();
    let initial_balance = player.balance;
    let fee = 50_u256;

    let result = player.pay_fee(fee);

    assert(result, 'Fee payment should succeed');
    assert(player.balance == initial_balance - fee, 'Wrong balance after fee');
}

#[test]
fn test_pay_fee_insufficient_funds() {
    let mut player = create_test_player();
    let fee = 2000_u256;

    let result = player.pay_fee(fee);

    assert(!result, 'Fee payment should fail');
}

#[test]
fn test_can_afford() {
    let player = create_test_player();

    assert(player.can_afford(1500_u256), 'Should afford exact balance');
    assert(player.can_afford(1000_u256), 'Should afford less than balance');
    assert(!player.can_afford(2000_u256), 'Should not afford');
}

#[test]
fn test_is_bankrupt() {
    let mut player = create_test_player();

    assert(!player.is_bankrupt(), 'Should not be bankrupt');

    player.balance = 0;
    assert(player.is_bankrupt(), 'Should be bankrupt');
}

#[test]
fn test_get_win_rate() {
    let mut player = create_test_player();

    assert(player.get_win_rate() == 0, 'Win rate should be 0');

    player.total_games_completed = 5;
    player.total_games_won = 2;
    assert(player.get_win_rate() == 40, 'Win rate should be 40%');

    player.total_games_completed = 3;
    player.total_games_won = 3;
    assert(player.get_win_rate() == 100, 'Win rate should be 100%');
}

#[test]
fn test_player_symbol_is_valid() {
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Hat), 'Hat should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Car), 'Car should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Dog), 'Dog should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Thimble), 'Thimble should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Iron), 'Iron should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Battleship), 'Battleship should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Boot), 'Boot should be valid');
    assert(PlayerSymbolImpl::is_valid(PlayerSymbol::Wheelbarrow), 'Wheelbarrow should be valid');
}

#[test]
fn test_player_symbol_get_name() {
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Hat) == 'Hat', 'Wrong hat name');
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Car) == 'Car', 'Wrong car name');
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Dog) == 'Dog', 'Wrong dog name');
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Thimble) == 'Thimble', 'Wrong thimble name');
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Iron) == 'Iron', 'Wrong iron name');
    assert(
        PlayerSymbolImpl::get_name(PlayerSymbol::Battleship) == 'Battleship',
        'Wrong battleship name',
    );
    assert(PlayerSymbolImpl::get_name(PlayerSymbol::Boot) == 'Boot', 'Wrong boot name');
    assert(
        PlayerSymbolImpl::get_name(PlayerSymbol::Wheelbarrow) == 'Wheelbarrow',
        'Wrong wheelbarrow name',
    );
}

#[test]
fn test_player_symbol_from_felt() {
    assert(
        PlayerSymbolImpl::from_felt('Hat') == Option::Some(PlayerSymbol::Hat),
        'Wrong hat conversion',
    );
    assert(
        PlayerSymbolImpl::from_felt('Car') == Option::Some(PlayerSymbol::Car),
        'Wrong car conversion',
    );
    assert(
        PlayerSymbolImpl::from_felt('Dog') == Option::Some(PlayerSymbol::Dog),
        'Wrong dog conversion',
    );
    assert(
        PlayerSymbolImpl::from_felt('Invalid') == Option::None, 'Should return None for invalid',
    );
}

#[test]
fn test_validate_creation_success() {
    let result = PlayerValidationImpl::validate_creation(
        'TestPlayer', contract_address_const::<0x123>(), PlayerSymbol::Hat, 1500_u256,
    );
    assert(result, 'Valid creation should pass');
}

#[test]
fn test_validate_creation_zero_address() {
    let result = PlayerValidationImpl::validate_creation(
        'TestPlayer', zero_address(), PlayerSymbol::Hat, 1500_u256,
    );
    assert(!result, 'Should fail validation');
}

#[test]
fn test_validate_creation_empty_username() {
    let result = PlayerValidationImpl::validate_creation(
        0, contract_address_const::<0x123>(), PlayerSymbol::Hat, 1500_u256,
    );
    assert(!result, 'Should fail validation');
}

#[test]
fn test_validate_transaction_success() {
    let payer = create_test_player();
    let recipient = create_test_bot();

    let result = PlayerValidationImpl::validate_transaction(@payer, @recipient, 100_u256);
    assert(result, 'Valid transaction should pass');
}

#[test]
fn test_validate_transaction_insufficient_funds() {
    let payer = create_test_player();
    let recipient = create_test_bot();

    let result = PlayerValidationImpl::validate_transaction(@payer, @recipient, 2000_u256);
    assert(!result, 'Should fail validation');
}

#[test]
fn test_validate_transaction_same_player() {
    let player = create_test_player();

    let result = PlayerValidationImpl::validate_transaction(@player, @player, 100_u256);
    assert(!result, 'Should fail validation');
}

#[test]
fn test_validate_transaction_zero_amount() {
    let payer = create_test_player();
    let recipient = create_test_bot();

    let result = PlayerValidationImpl::validate_transaction(@payer, @recipient, 0_u256);
    assert(!result, 'Should fail validation');
}

#[test]
fn test_validate_username() {
    assert(PlayerValidationImpl::validate_username('ValidName'), 'Valid username should pass');
    assert(!PlayerValidationImpl::validate_username(0), 'Zero username should fail');
}

// PlayerActions Tests
#[test]
fn test_go_to_jail() {
    let mut player = create_test_player();

    player.go_to_jail();

    assert(player.jailed, 'Should be jailed');
    assert(player.position == 10, 'Should be at jail position');
}

#[test]
fn test_get_out_of_jail_with_payment() {
    let mut player = create_test_player();
    player.jailed = true;
    let initial_balance = player.balance;
    let fee = 50_u256;

    let result = player.get_out_of_jail(true, fee);

    assert(result, 'Should get out of jail');
    assert(!player.jailed, 'Should not be jailed');
    assert(player.balance == initial_balance - fee, 'Wrong balance after fee');
}

#[test]
fn test_get_out_of_jail_without_payment() {
    let mut player = create_test_player();
    player.jailed = true;
    let initial_balance = player.balance;

    let result = player.get_out_of_jail(false, 0);

    assert(result, 'Should get out of jail');
    assert(!player.jailed, 'Should not be jailed');
    assert(player.balance == initial_balance, 'Balance should not change');
}

#[test]
fn test_get_out_of_jail_insufficient_funds() {
    let mut player = create_test_player();
    player.jailed = true;
    let fee = 2000_u256;

    let result = player.get_out_of_jail(true, fee);

    assert(!result, 'Should fail to get out of jail');
    assert(player.jailed, 'Should still be jailed');
}

#[test]
fn test_pass_go() {
    let mut player = create_test_player();
    let initial_balance = player.balance;
    let go_amount = 200_u256;

    player.pass_go(go_amount);

    assert(player.balance == initial_balance + go_amount, 'Wrong balance after passing go');
}

#[test]
fn test_pay_tax_successful() {
    let mut player = create_test_player();
    let initial_balance = player.balance;
    let tax = 100_u256;

    let result = player.pay_tax(tax);

    assert(result, 'Tax payment should succeed');
    assert(player.balance == initial_balance - tax, 'Wrong balance after tax');
}

#[test]
fn test_pay_tax_insufficient_funds() {
    let mut player = create_test_player();
    let tax = 2000_u256;

    let result = player.pay_tax(tax);

    assert(!result, 'Tax payment should fail');
}

#[test]
fn test_receive_money() {
    let mut player = create_test_player();
    let initial_balance = player.balance;
    let amount = 300_u256;

    player.receive_money(amount);

    assert(player.balance == initial_balance + amount, 'Wrong balance');
}

#[test]
fn test_reset_position() {
    let mut player = create_test_player();
    player.position = 25;
    player.jailed = true;

    player.reset_position();

    assert(player.position == 0, 'Position should be reset to 0');
    assert(!player.jailed, 'Should not be jailed');
}


#[test]
fn test_multiple_operations() {
    let mut player1 = create_test_player();
    let mut player2 = create_test_bot();

    player1.move_player(42, 40);
    assert(player1.position == 2, 'Wrong position after move');
    assert(player1.balance == 1700, 'Wrong balance after passing go');

    let rent_paid = player1.pay_rent_to(ref player2, 150_u256);
    assert(rent_paid, 'Rent payment should succeed');
    assert(player1.balance == 1550, 'Wrong balance after rent');
    assert(player2.balance == 1650, 'Wrong recipient balance');

    player1.go_to_jail();
    assert(player1.jailed, 'Should be jailed');
    assert(player1.position == 10, 'Should be at jail');

    let jail_exit = player1.get_out_of_jail(true, 50_u256);
    assert(jail_exit, 'Should get out of jail');
    assert(player1.balance == 1500, 'Wrong balance after jail fee');
}
