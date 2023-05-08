// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import {ILendingPoolConfigurator} from '../interfaces/ILendingPoolConfigurator.sol';

contract TestConfig {

  address constant POOL_CONFIGURATOR = 0x2F75fEDA7423D8B85988d9545428d00f3213CF00; //Config for non production Lending pools 
  address constant myreserves = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;
  address constant myoTokenImplementations = 0x63D03492cD26c0C1f73a563f7eaB79b52334852A;

  function executeFixed() external  {   
    ILendingPoolConfigurator poolConfigurator = ILendingPoolConfigurator(POOL_CONFIGURATOR);
    // Update oToken impl
    poolConfigurator.updateOToken(myreserves, myoTokenImplementations);
  }

  function executeChange (address _reserves, address _myoTokenImplementations) external  {   
    ILendingPoolConfigurator poolConfigurator = ILendingPoolConfigurator(POOL_CONFIGURATOR);
    // Update oToken impl
    poolConfigurator.updateOToken(_reserves, _myoTokenImplementations);

  }
}


