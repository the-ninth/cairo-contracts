%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_lt

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
    FirstRelicCombat_combat_account_koma_creatures,
)

from contracts.util.math import felt_lt

namespace ManageLibrary {
    func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        combat_id: felt, account: felt, koma_creature_id: felt
    ) {
        FirstRelicCombat_combat_account_koma_creatures.write(combat_id, account, koma_creature_id);
        return ();
    }

    func check_combat_account_registered{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(combat_id: felt, account: felt) -> (registered: felt) {
        let (koma_creature_id) = FirstRelicCombat_combat_account_koma_creatures.read(
            combat_id, account
        );
        let (registered) = felt_lt(0, koma_creature_id);
        return (registered,);
    }
}
