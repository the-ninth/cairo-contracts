%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.security.safemath.library import SafeUint256

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import NINTH_CONTRACT, KOMA_CONTRACT
from contracts.pvp.first_relic.IFirstRelicCombat import IFirstRelicCombat
from contracts.pvp.first_relic.constants import REGISTER_FEE
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_access_contract,
    FirstRelicCombat_combat_account_koma_tokens,
    FirstRelicCombat_register_fee,
)

namespace ManageLibrary {
    func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        combat_id: felt, account: felt, koma_token_id: Uint256
    ) {
        let (self) = get_contract_address();
        let (access_contract_address) = FirstRelicCombat_access_contract.read();

        let (koma_contract_address) = IAccessControl.getContractAddress(
            contract_address=access_contract_address, contract_name=KOMA_CONTRACT
        );
        let (tokenOwner) = IERC721.ownerOf(
            contract_address=koma_contract_address, tokenId=koma_token_id
        );
        with_attr error_message("invalid koma token") {
            assert tokenOwner = account;
        }
        FirstRelicCombat_combat_account_koma_tokens.write(combat_id, account, koma_token_id);
        return ();
    }

    func get_combat_account_koma_token{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(combat_id: felt, account: felt) -> (koma_token_id: Uint256) {
        let (koma_token_id) = FirstRelicCombat_combat_account_koma_tokens.read(combat_id, account);
        return (koma_token_id,);
    }
}
