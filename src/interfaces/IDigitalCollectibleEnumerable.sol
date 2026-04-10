// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IDigitalCollectible } from "./IDigitalCollectible.sol";

interface IDigitalCollectibleEnumerable is IDigitalCollectible, IERC721Enumerable { }
