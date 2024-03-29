%lang starknet

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.library import ERC721

const BUILDING_TYPE_LUMBER_CAMP = 1;
const BUILDING_TYPE_QUARRY = 2;
const BUILDING_TYPE_FARM = 3;

struct Land {
    building_type: felt,
}

@storage_var
func Land_lands(tokenId: Uint256) -> (land: Land) {
}

@view
func Land_getLand{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (land: Land) {
    ERC721.owner_of(tokenId);
    let (land) = Land_lands.read(tokenId);
    return (land,);
}

func Land_build{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, buildingType: felt
) {
    let (land: Land) = Land_getLand(tokenId);
    assert land.building_type = 0;
    land.building_type = buildingType;
    Land_lands.write(tokenId, land);
    return ();
}
