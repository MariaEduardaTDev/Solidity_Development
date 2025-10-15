//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is ERC20, AccessControl { /// Criando um novo contrato "Token" que herda as funções dos dois contratos: ERC20 e AccessControl
    /// Criando MINTER:
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); /// Tipo de dado da variável "32 bytes" | "constant" - torna o valor imutável


    constructor() ERC20("Token TAVS 2025", "TAVS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); /// Concede ao criador do contrato o papel de administrador | Já um default do Openzappelin
        _grantRole(MINTER_ROLE, msg.sender); /// Concede ao criador do contrato o papel de minter
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) { /// Emite tokens para alguém (endereço) e sua quantidade (amount) - Somente quem está na MINTER_ROLE
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) { /// Sobrescrevendo a função decimals do opezeppelin para ter apenas 2 casa decimais
        return 2;
    }
}