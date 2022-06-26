%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.ERC20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.security.safemath import uint256_checked_add

from contracts.access.interfaces.IAccessControl import IAccessControl
from contracts.access.library import NINTH_CONTRACT, KOMA_CONTRACT
from contracts.pvp.first_relic.IFirstRelicCombat import IFirstRelicCombat
from contracts.pvp.first_relic.constants import REGISTER_FEE
from contracts.pvp.first_relic.storages import (
    FirstRelicCombat_access_contract,
    FirstRelicCombat_combat_account_koma_ids,
    FirstRelicCombat_register_fee,
)

namespace ManageLibrary:
    func register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        combat_id : felt, account : felt, koma_id : Uint256
    ):
        let (self) = get_contract_address()
        let (access_contract_address) = FirstRelicCombat_access_contract.read()
        let (ninth_contract_address) = IAccessControl.getContractAddress(
            contract_address=access_contract_address, contract_name=NINTH_CONTRACT
        )
        let register_fee = Uint256(REGISTER_FEE, 0)
        let (res) = IERC20.transferFrom(
            contract_address=ninth_contract_address,
            sender=account,
            recipient=self,
            amount=register_fee,
        )
        assert res = TRUE
        let (total) = FirstRelicCombat_register_fee.read(combat_id)
        let (new_total) = uint256_checked_add(total, register_fee)

        let (koma_contract_address) = IAccessControl.getContractAddress(
            contract_address=access_contract_address, contract_name=KOMA_CONTRACT
        )
        IERC721.transferFrom(
            contract_address=koma_contract_address, from_=account, to=self, tokenId=koma_id
        )
        FirstRelicCombat_combat_account_koma_ids.write(combat_id, account, koma_id)
        FirstRelicCombat_register_fee.write(combat_id, new_total)
        return ()
    end

    func get_combat_account_koma_id{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(combat_id : felt, account : felt) -> (koma_id : Uint256):
        let (koma_id) = FirstRelicCombat_combat_account_koma_ids.read(combat_id, account)
        return (koma_id)
    end
end