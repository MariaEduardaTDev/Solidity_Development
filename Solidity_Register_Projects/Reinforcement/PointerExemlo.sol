// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PointerExample {

    // Declarando uma Array no storage (memória permanente na blockchain) 
    uint256[] public storageArray = [2,3,4];

    function manipulateArray() public {

        // Criando um ponteiro da array original
        uint256[] storage storageArrayPointer = storageArray;

        // Modificando o valor armazenado no índice 0 na array original por 100
        storageArrayPointer[0] = 100;

        // Criando uma variável que armazena a cópia do valor da array original
        uint256[] memory storageArrayCopy = storageArray;

        // Modifica o valor somente na memória, não altera a array original
        storageArrayCopy[1] = 46;
    }

    function getStorageArray() public view returns (uint256[] memory) {
        return storageArray;
    }

}