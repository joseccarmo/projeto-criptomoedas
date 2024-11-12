// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DAOAudit {
    // Estrutura para representar uma decisão
    struct Decision {
        uint256 id;
        string description;
        uint256 timestamp;
        address proposer;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        address externalContract;
        bytes4 externalFunctionSignature;
    }
    // Estrutura para representar um voto
    struct Vote {
        uint256 decisionId;
        address voter;
        bool inFavor;
        uint256 timestamp;
    }

    // Mapeamentos
    mapping(uint256 => Decision) public decisions;
    mapping(uint256 => Vote[]) public votes; // Armazena votos de cada decisão
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // salva número de votações
    uint256 public decisionCount;

    // votação criada
    event DecisionProposed(uint256 id, address proposer, string description, uint256 timestamp);
    //votação executada
    event DecisionExecuted(uint256 id, address executor, uint256 timestamp, bool success);
    //voto registrado
    event VoteCasted(uint256 decisionId, address voter, bool inFavor, uint256 timestamp);

    // cria nova votação
    function proposeDecision(
        string memory _description, 
        address _externalContract,
        bytes4 _externalFunctionSignature
        ) public {
        decisionCount++;
        decisions[decisionCount] = Decision({
            id: decisionCount,
            description: _description,
            timestamp: block.timestamp,
            proposer: msg.sender,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            externalContract: _externalContract,
            externalFunctionSignature: _externalFunctionSignature
        });
        emit DecisionProposed(decisionCount, msg.sender, _description, block.timestamp);
    }

    // registra um voto
    function castVote(uint256 _decisionId, bool _inFavor) public {
        require(_decisionId <= decisionCount, "Votacao inexistente");
        require(decisions[_decisionId].executed == false, "votacao encerrada");
        require(!hasVoted[_decisionId][msg.sender], "Apenas um voto por pessoa");

        votes[_decisionId].push(Vote({
            decisionId: _decisionId,
            voter: msg.sender,
            inFavor: _inFavor,
            timestamp: block.timestamp
        }));

        if (_inFavor) {
            decisions[_decisionId].yesVotes++;
        } else {
            decisions[_decisionId].noVotes++;
        }

        emit VoteCasted(_decisionId, msg.sender, _inFavor, block.timestamp);
    }

    //finaliza uma execução
    function endDecision(uint256 _decisionId) public {
        require(_decisionId <= decisionCount, "votacao nao existe");
        require(!decisions[_decisionId].executed, "votacao terminada");
        require(decisions[_decisionId].proposer == msg.sender, "voce nao e o criador da votacao");

        decisions[_decisionId].executed = true;

        bool success = false;
        if (decisions[_decisionId].yesVotes > decisions[_decisionId].noVotes) {
            (success, ) = decisions[_decisionId].externalContract.call(
                abi.encodeWithSelector(decisions[_decisionId].externalFunctionSignature)
            );
        }

        emit DecisionExecuted(_decisionId, msg.sender, block.timestamp, success);
    }

    // retorna uma lista de votos de uma votação em especifico
    function getDecisionVotes(uint256 _decisionId) public view returns (Vote[] memory) {
        return votes[_decisionId];
    }
    
    //retorna os dados de uma votação
    function getDecision(uint256 _decisionId) public view returns (Decision memory) {
        return decisions[_decisionId];
    }
    // Função para listar todas as propostas abertas (não executadas)
    function getOpenDecisions() public view returns (Decision[] memory) {
        uint256 openCount = 0;

        // Primeiro, contamos o número de decisões abertas
        for (uint256 i = 1; i <= decisionCount; i++) {
            if (!decisions[i].executed) {
                openCount++;
            }
        }

        // Criamos um array para armazenar as decisões abertas
        Decision[] memory openDecisions = new Decision[](openCount);
        uint256 index = 0;

        // Adicionamos as decisões abertas ao array
        for (uint256 i = 1; i <= decisionCount; i++) {
            if (!decisions[i].executed) {
                openDecisions[index] = decisions[i];
                index++;
            }
        }

        return openDecisions;
    }

    event simpleDecisionExecuted(string description, uint256 timestamp);
    //4bytes: 0xb6db337a
    function simpleDecision() public  {
        emit simpleDecisionExecuted("votacao simples", block.timestamp);
    }
}
