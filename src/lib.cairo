// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.8.0 (presets/erc721.cairo)

/// # ERC721 Preset
///
/// The ERC721 contract offers a batch-mint mechanism that
/// can only be executed once upon contract construction.
#[starknet::contract]
mod ERC721 {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_block_timestamp};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        count: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    mod Errors {
        const UNEQUAL_ARRAYS: felt252 = 'Array lengths do not match';
    }

    /// Sets the token `name` and `symbol`.
    /// Mints the `token_ids` tokens to `recipient` and sets
    /// each token's URI.
    #[constructor]
    fn constructor(ref self: ContractState) {
        let name: felt252 = 'GoldenToken';
        let symbol: felt252 = 'GTKN';

        self.erc721.initializer(name, symbol);
    }

    #[starknet::interface]
    trait IGoldenToken<TContractState> {
        fn mint(ref self: TContractState);
    }

    #[abi(embed_v0)]
    impl GoldenTokenImpl of IGoldenToken<ContractState> {
        fn mint(ref self: ContractState) {
            let mut current_count = self.count.read();

            current_count += 1;

            // Mint the token.
            self.erc721._mint(get_caller_address(), current_count.into());

            self.count.write(current_count);
        }
    }

    fn _token_uri(self: @ContractState, token_id: u256) -> Array::<felt252> {
        assert(self.erc721._exists(token_id), 'ERC721: invalid token ID');

        let mut content = ArrayTrait::<felt252>::new();

        // Name & Description
        content.append('data:application/json;utf8,');
        content.append('{"name":"Golden Token",');
        content.append('"description":"One free game, ');
        content.append('every day, forever"');

        // Image
        content.append(',"image":"');
        content.append('data:image/svg+xml;utf8,<svg%20');
        content.append('width=\\"100%\\"%20height=\\"100%\\');
        content.append('"%20viewBox=\\"0%200%2020000%202');
        content.append('0000\\"%20xmlns=\\"http://www.w3.');
        content.append('org/2000/svg\\"><style>svg{backg');
        content.append('round-image:url(');
        content.append('data:image/png;base64,');

        // Golden Token Base64 Encoded PNG
        content.append('iVBORw0KGgoAAAANSUhEUgAAAUAAAAF');
        content.append('ABAMAAAA/vriZAAAAD1BMVEUAAAD4+A');
        content.append('CJSQL/pAD///806TM9AAACgUlEQVR4A');
        content.append('WKgGAjiBUqoANDOHdzGDcRQAK3BLaSF');
        content.append('tJD+awriQwh8zDd2srlQfjxJGGr4xhf');
        content.append('Csuj3ywEC7gcCAgKeCD9bVC8gICAg4H');
        content.append('cDVtGvP/G5MKIXvKF8MhAQEBAQMFifo');
        content.append('rmK+Iho8uh8zwMCAgICAk65aouaEVM9');
        content.append('WL3zAQICAgJuBqYtth7brEZHC2CcMI6');
        content.append('Z1FQCAgICAm4GTnZsGL8WRaW4inPVV3');
        content.append('eAgICAgI8CVls0uIr+WnnR7wABAQEBF');
        content.append('wAvbBn3ytrvuhIQEBAQcCvwa8IbygCm');
        content.append('DRAQEBBwK7DbTt8A/OdWl7ZUAgICAgL');
        content.append('uAp5slXD1+i2BzQYICAgIuBsYtigyf8');
        content.append('2Z+GjRkhMYNQABAQEBdwFfsVXgRLd1Y');
        content.append('Dl/yAEBAQEB9wDrO7OoOQtRvdpeGKec');
        content.append('AAQEBATcCsxWd7qNwh1YItG15EYgICA');
        content.append('gIOAopyudHp6FuApgTRlgKbkTCAgICA');
        content.append('g4jhAl8NCz/u31W2+na4GAgICAgHFVh');
        content.append('+ZPtkmJvEiuNeYMa4CAgICAgPlxWSxP');
        content.append('nERhS0zE4XDR78rAyw4gICAgIGASYte');
        content.append('UN1soJyV+CGOL7QEBAQEBnwTs20yl+t');
        content.append('VZvFGLhTpUsxAICAgICJjKfORvvD06O');
        content.append('cAL2zogICAgIODJFg+fvknL25vR+7nd');
        content.append('CQQEBAQELMrYIeQ/XoxJvrItBAICAgI');
        content.append('CpvK0w2l8pUak3Nn2AwEBAQEB6z+sj/');
        content.append('1jin/yTlsFdT8QEBAQELAro1PF/lEpI');
        content.append('lJGHgthAwQEBATcD8wI5dxOzRr1C7PO');
        content.append('AgQEBAR8GjA7X1SqyjqxP0/cAJYDAQE');
        content.append('BAQGDGt46cJ/JyQIEBAQEfD7w0nsl2g');
        content.append('8EBAQEBPwNOZbOIEJQph0AAAAASUVOR');
        content.append('K5CYII=');

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
