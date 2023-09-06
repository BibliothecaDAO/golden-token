// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.7.0 (token/erc721/erc721.cairo)

use starknet::ContractAddress;

#[starknet::contract]
mod ERC721 {
    use core::traits::TryInto;
    use array::SpanTrait;
    use openzeppelin::account;

    use openzeppelin::access::ownable;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5Trait;
    use openzeppelin::introspection::interface::ISRC5;
    use openzeppelin::introspection::interface::ISRC5Camel;
    use openzeppelin::introspection::src5;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721Receiver;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721ReceiverTrait;
    use openzeppelin::token::erc721::interface;
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_block_timestamp};
    use zeroable::Zeroable;
    use openzeppelin::token::erc20::interface::{
        IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IERC20CamelLibraryDispatcher
    };

    const ETH: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
    const MINT_COST: u256 = 131088770000000000;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _owners: LegacyMap<u256, ContractAddress>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
        _operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        _token_uri: LegacyMap<u256, felt252>,
        _open_edition_end: u256,
        _count: u256,
        _open: bool,
        _owner: ContractAddress,
        _last_use: u256,
        _usage_count: LegacyMap<u256, u256>,
        _dao: ContractAddress
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        OwnershipTransferred: OwnershipTransferred
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        owner: ContractAddress,
        dao: ContractAddress
    ) {
        self.initializer(name, symbol);
        self._owner.write(owner);
        self._dao.write(dao);
    }

    //
    // External
    //

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = src5::SRC5::unsafe_new_contract_state();
            src5::SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }

    #[external(v0)]
    impl ERC721MetadataImpl of interface::IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.read(token_id)
        }
    }

    #[external(v0)]
    impl ERC721Impl of interface::IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), 'ERC721: invalid account');
            self._balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || ERC721Impl::is_approved_for_all(@self, owner, caller),
                'ERC721: unauthorized caller'
            );
            self._approve(to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(get_caller_address(), operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            self._transfer(from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            self._safe_transfer(from, to, token_id, data);
        }
    }

    #[starknet::interface]
    trait GoldenToken<TState> {
        fn usage_count(self: @TState, token_id: u256) -> u256;
        fn play(ref self: TState, token_id: u256);
        fn can_play(ref self: TState, token_id: u256) -> bool;
        fn last_usage(ref self: TState, token_id: u256) -> u256;
        fn mint(ref self: TState);
        fn open(ref self: TState);
    }

    const DAY: felt252 = 86400;
    const OPEN_EDITION_LENGTH_DAYS: u256 = 3;

    #[external(v0)]
    impl GoldenTokenImpl of GoldenToken<ContractState> {
        fn mint(ref self: ContractState) {
            let caller = get_caller_address();
            assert(self._open.read(), 'mint not open');
            assert(
                get_block_timestamp().into() < self._open_edition_end.read(),
                'open edition not available'
            );

            let tokenId = self._count.read();
            let new_tokenId = tokenId + 1;

            self._count.write(new_tokenId);
            self._mint(caller, new_tokenId);

            IERC20CamelDispatcher { contract_address: ETH.try_into().unwrap() }
                .transferFrom(caller, self._dao.read(), MINT_COST);
        }

        fn open(ref self: ContractState) {
            self.assert_only_owner();
            assert(!self._open.read(), 'already open');

            // open and set to 3 days from now
            self
                ._open_edition_end
                .write(get_block_timestamp().into() + DAY.into() * OPEN_EDITION_LENGTH_DAYS.into());
            self._open.write(true);
        }

        fn usage_count(self: @ContractState, token_id: u256) -> u256 {
            self._usage_count.read(token_id)
        }

        fn can_play(ref self: ContractState, token_id: u256) -> bool {
            self.last_usage(token_id)
                + DAY.into() < get_block_timestamp().into() || self.usage_count(token_id) == 0
        }

        fn play(ref self: ContractState, token_id: u256) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            assert(self._owner_of(token_id) == get_caller_address(), 'ERC721: not owner');

            let usage_count = self.usage_count(token_id);
            assert(
                self.last_usage(token_id)
                    + DAY.into() < get_block_timestamp().into() || self.usage_count(token_id) == 0,
                'ERC721: already used today'
            );

            self._last_use.write(get_block_timestamp().into());
            self._usage_count.write(token_id, usage_count + 1);
        }

        fn last_usage(ref self: ContractState, token_id: u256) -> u256 {
            self._last_use.read()
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252) {
            self._name.write(name_);
            self._symbol.write(symbol_);

            let mut unsafe_state = src5::SRC5::unsafe_new_contract_state();
            src5::SRC5::InternalImpl::register_interface(ref unsafe_state, interface::IERC721_ID);
            src5::SRC5::InternalImpl::register_interface(
                ref unsafe_state, interface::IERC721_METADATA_ID
            );
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self._owners.read(token_id).is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = ERC721Impl::is_approved_for_all(self, owner, spender);
            owner == spender
                || is_approved_for_all
                || spender == ERC721Impl::get_approved(self, token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, 'ERC721: approval to owner');

            self._token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, 'ERC721: self approval');
            self._operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            assert(!self._exists(token_id), 'ERC721: token already minted');

            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = self._owner_of(token_id);
            assert(from == owner, 'ERC721: wrong sender');

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(from, self._balances.read(from) - 1);
            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self._owner_of(token_id);

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(owner, self._balances.read(owner) - 1);
            self._owners.write(token_id, Zeroable::zero());

            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._mint(to, token_id);
            assert(
                _check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                'ERC721: safe mint failed'
            );
        }

        fn _safe_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            assert(
                _check_on_erc721_received(from, to, token_id, data), 'ERC721: safe transfer failed'
            );
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.write(token_id, token_uri)
        }

        fn assert_only_owner(self: @ContractState) {
            let owner: ContractAddress = self._owner.read();
            let caller: ContractAddress = get_caller_address();
            assert(!caller.is_zero(), 'Caller is the zero address');
            assert(caller == owner, 'Caller is not the owner');
        }

        fn _transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let previous_owner: ContractAddress = self._owner.read();
            self._owner.write(new_owner);
            self
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                );
        }
        fn _token_uri(self: @ContractState, token_id: u256) -> Array::<felt252> {
            assert(self._exists(token_id), 'ERC721: invalid token ID');

            let mut content = ArrayTrait::<felt252>::new();

            // Name & description
            content.append('data:application/json;utf8,');
            content.append('{"name":"\"');
            content.append('Golden Token');
            content.append('","description":"Beasts"');

            // // Metadata
            // content.append(',"attributes":[{"trait_type":');
            // content.append('"prefix","value":"');
            // content.append(prefix);
            // content.append('"},{"trait_type":');
            // content.append('"name","value":"');
            // content.append(name);
            // content.append('"},{"trait_type":');
            // content.append('"suffix","value":"');
            // content.append(suffix);
            // content.append('"},{"trait_type":');
            // content.append('"type","value":"');
            // content.append(btype);
            // content.append('"},{"trait_type":');
            // content.append('"tier","value":"');
            // content.append(tier);
            // content.append('"},{"trait_type":');
            // content.append('"level","value":"');
            // content.append(level);
            content.append('"}]');

            // Image
            content.append(',"image":"');
            content.append('data:image/svg+xml;utf8,<svg%20');
            content.append('width=\\"100%\\"%20height=\\"100%\\');
            content.append('"%20viewBox=\\"0%200%2020000%202');
            content.append('0000\\"%20xmlns=\\"http://www.w3.');
            content.append('org/2000/svg\\"><style>svg{backg');
            content.append('round-image:url(');
            content.append('data:image/png;base64,');

            // TODO: add in SVG COIN
            content.append('iVBORw0KGgoAAAANSUhEUgAAACAAAAA');
            content.append('gCAIAAAD8GO2jAAAAAXNSR0IArs4c6Q');
            content.append('AAAR5JREFUSImdVkkSwzAIw5k8uk/wr');
            content.append('91DmgxFIOQwvQTLIFbX7JY1DWXNUq8K');
            content.append('gRLr1RHK8NfGJzr2mpQQAnJGKUeDIJB');
            content.append('7G8pItWk0hK/3ETDjhTnuo7n1ZIYAeP');
            content.append('FLz202Mfuqj/RANCcq+1aphHRgRHi7o');
            content.append('vUUkDhAhBVxpCnmQZwVKHQbxqQ08Zp2');
            content.append('BKPXL5Vw5Buf7I8jvYxE0svKvjusCxY');
            content.append('TgtkjQTd0yPT59iOAs0VwdoT+H8cXY1');
            content.append('zpwzCdyBGX69ZaZbL1mCj0LQzaw/T5x');
            content.append('NSpqb/l5+CyRR4Nz6Cyrk/43wUzqeAV');
            content.append('nqFDg4klSVey5I/oK+5r3jVo7fLM7la');
            content.append('evewVA7UAol1u1H/GB+fF0DbDoadi63');
            content.append('/GRgths+o+1rQvxnQq3zSqGWEAAAAAS');
            content.append('UVORK5CYII=');

            content.append(');background-repeat:no-repeat;b');
            content.append('ackground-size:contain;backgrou');
            content.append('nd-position:center;image-render');
            content.append('ing:-webkit-optimize-contrast;-');
            content.append('ms-interpolation-mode:nearest-n');
            content.append('eighbor;image-rendering:-moz-cr');
            content.append('isp-edges;image-rendering:pixel');
            content.append('ated;}</style></svg>"}');

            content
        }
    }


    #[external(v0)]
    impl OwnableImpl of ownable::interface::IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self._owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            assert(!new_owner.is_zero(), 'New owner is the zero address');
            self.assert_only_owner();
            self._transfer_ownership(new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            self.assert_only_owner();
            self._transfer_ownership(Zeroable::zero());
        }
    }

    #[internal]
    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
    ) -> bool {
        if (DualCaseSRC5 { contract_address: to }
            .supports_interface(interface::IERC721_RECEIVER_ID)) {
            DualCaseERC721Receiver { contract_address: to }
                .on_erc721_received(
                    get_caller_address(), from, token_id, data
                ) == interface::IERC721_RECEIVER_ID
        } else {
            DualCaseSRC5 { contract_address: to }.supports_interface(account::interface::ISRC6_ID)
        }
    }
}
