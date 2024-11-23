// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // bytes32 public constant PERMIT_TYPEHASH =
    //     0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    struct Bondlink {
        address contractAddress;
        address account;
        uint256 nonce;
    }

    // computes the hash of a bondlink
    function getStructHash(Bondlink memory _bondlink)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                      "Bondlink(address contractAddress,address account,uint256 nonce)"
                    ),
                    // PERMIT_TYPEHASH,
                    _bondlink.contractAddress,
                    _bondlink.account,
                    _bondlink.nonce
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Bondlink memory _bondlink)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_bondlink)
                )
            );
    }
}
