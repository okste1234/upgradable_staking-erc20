// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/facets/LayoutChangerFacet.sol";
import "../contracts/facets/WCXTokenFacet.sol";
import "../contracts/facets/StakingFacet.sol";

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/RCXToken.sol";

import "../contracts/libraries/LibAppStorage.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    LayoutChangerFacet lFacet;
    WCXTokenFacet wcxFacet;
    RCXToken rcxToken;
    StakingFacet stakingF;

    // stake

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        lFacet = new LayoutChangerFacet();
        wcxFacet = new WCXTokenFacet();
        rcxToken = new RCXToken();
        stakingF = new StakingFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](5);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(lFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LayoutChangerFacet")
            })
        );
        cut[3] = (
            FacetCut({
                facetAddress: address(wcxFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("WCXTokenFacet")
            })
        );
        cut[4] = (
            FacetCut({
                facetAddress: address(stakingF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StakingFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testLayoutfacet() public {
        LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
        // l.getLayout();
        l.ChangeNameAndNo(777, "one guy");

        //check outputs
        LibAppStorage.Layout memory la = l.getLayout();

        assertEq(la.name, "one guy");
        assertEq(la.currentNo, 777);
    }

    // function testLayoutfacet2() public {
    //     LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
    //     //check outputs
    //     LibAppStorage.Layout memory la = l.getLayout();

    //     assertEq(la.name, "one guy");
    //     assertEq(la.currentNo, 777);
    // }

    function testWcxFacet() public {
        WCXTokenFacet wcx = WCXTokenFacet(address(diamond));
        wcx.init();
        //check outputs
        assertEq(wcx.symbol(), "WCX");
    }

    function testStakingFacet() public {
        WCXTokenFacet wcx = WCXTokenFacet(address(diamond));
        wcx.init();
        StakingFacet s = StakingFacet(address(diamond));
        wcx.approve(address(diamond), 1000000000);
        wcx.approve(address(s), 1000000000);

        // RCXToken r = RCXToken(address(rcxToken));
        s.init(address(wcx), address(rcxToken));
        uint256 _amount = 100;
        s.stake(_amount);
        //check outputs
        uint totalAmountStaked = s.contractBalance();
        assertEq(totalAmountStaked, _amount);
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
