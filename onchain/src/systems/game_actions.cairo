use starkludo::models::{game::{Game, GameTrait, GameMode, GameStatus}, player::{Player}};
use starknet::{ContractAddress, get_block_timestamp};

#[starknet::interface]
trait IGameActions<T> {
    fn create(
        ref self: T,
        game_mode: GameMode,
        player_green: felt252,
        player_yellow: felt252,
        player_blue: felt252,
        player_red: felt252,
        number_of_players: u8
    ) -> usize;
    fn start(ref self: T);

    fn join(ref self: T);

    fn move(ref self: T);

    fn roll(ref self: T) -> (u8, u8);

    fn get_username_from_address(ref self: T, address: ContractAddress) -> felt252;

    fn get_address_from_username(ref self: T, username: felt252) -> ContractAddress;
}

#[dojo::contract]
pub mod GameActions {
    use core::array::ArrayTrait;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starkludo::models::player::{AddressToUsername, UsernameToAddress};
    use super::{IGameActions, Game, GameTrait, GameMode, Player, GameStatus};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use origami_random::dice::{Dice, DiceTrait};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
        #[key]
        pub game_id: usize,
        pub timestamp: u64
    }

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create(
            ref self: ContractState,
            game_mode: GameMode,
            player_green: felt252,
            player_yellow: felt252,
            player_blue: felt252,
            player_red: felt252,
            number_of_players: u8,
        ) -> usize {
            // Get default world
            let mut world = self.world_default();

            let game_id = 999;
            let timestamp = get_block_timestamp();

            // Get the account address of the caller
            let caller = get_caller_address();

            let caller_username = self.get_username_from_address(caller);

            // Create a new game
            let new_game: Game = GameTrait::new(
                game_id,
                caller_username,
                game_mode,
                player_red,
                player_blue,
                player_yellow,
                player_green,
                number_of_players
            );

            world.write_model(@new_game);

            world.emit_event(@GameCreated { game_id, timestamp });

            game_id
        }

        fn start(ref self: ContractState) {}

        fn join(ref self: ContractState) {}

        fn move(ref self: ContractState) {}


        fn roll(ref self: ContractState) -> (u8, u8) {
            let seed = get_block_timestamp();

            let mut dice1 = DiceTrait::new(6, seed.try_into().unwrap());
            let mut dice2 = DiceTrait::new(6, (seed + 1).try_into().unwrap());

            let dice1_roll = dice1.roll();
            let dice2_roll = dice2.roll();

            (dice1_roll, dice2_roll)
        }


        fn get_username_from_address(ref self: ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }

        fn get_address_from_username(
            ref self: ContractState, username: felt252
        ) -> ContractAddress {
            let mut world = self.world_default();

            let username_map: UsernameToAddress = world.read_model(username);

            username_map.address
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "starkludo". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"starkludo")
        }
    }
}
