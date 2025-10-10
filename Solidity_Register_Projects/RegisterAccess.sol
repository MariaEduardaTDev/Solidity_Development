// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract RegisterAccess {
    string[] private info; 
    address public owner;
    mapping (address => bool) public allowlist; /// Atribui uma autorização (true)/ negação(false) do endereço na allowlist

    constructor() { /// Executado ao criar o contrato
        owner = msg.sender; /// Atribui o endereço de quem executou a transação de criação do contrato ao owner (dono)
        allowlist[msg.sender] = true; /// Endereço do dono atribuido como true na allowlist 
    }

    event InfoChange (string oldInfo, string newInfo); /// Evento que sinaliza a alteração da info

    modifier onlyOwner{ /// Requisito criado para que apenas o dono execute determinadas funções
        require(msg.sender == owner, "Only owner."); /// Se não, exibe a mensagem
        _; /// Se sim, continua o código
    }

    modifier onlyAllowlist { /// Requisito para que apenas pessoas na lista de autorizados executem determinadas funções
        require(allowlist[msg.sender] == true, "Only allowlist."); /// Se não, exibe a mensagem
        _; /// Se sim, continua o código
    }

    function getInfo(uint index) public view returns (string memory) { /// Recebe o valor do índice 
        return info[index]; /// Exibe os dados do índice específico 
    }

    function setInfo(uint index, string memory _info) public onlyAllowlist { /// Recebe o índice e os novos dados 
        emit InfoChange(info[index], _info); /// Emite o evento dos dados antigos e os novos
        info[index] = _info; /// Atribui o novo valor à variável na posição específica
    }

    function addInfo(string memory _info) public onlyAllowlist returns (uint index) { /// Recebe os dados 
        info.push(_info); /// Adiciona os dados no array
        index = info.length -1; /// Na posição do tamanho do array -1 (índice: 0,1,2...)
    }

    function listInfo() public view returns (string[] memory) { /// Exibe todos as informações da lista
        return info;
    }

    function addMember (address _member) public onlyOwner { /// Recebe o endereço 
        allowlist[_member] = true; /// Somente executado pelo dono, adiciona o endereço à lista de autorizados
    }

    function delMember (address _member) public onlyOwner {/// Recebe o endereço 
        allowlist[_member] = false; /// Somente executado pelo dono, "deleta" (torna falso) o endereço da lista de autorizados 
    }
}