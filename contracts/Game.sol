//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

import "hardhat/console.sol";

contract Game {
    
    //atento a este evento, es el que nos devuelve el id para hacer la consulta
    event NewGame(uint id);

    struct Match {
        address playerOne;
        address playerTwo;
        uint bet;
        bool wasTransfered;
        uint8 winner;
        uint timestamp;
    }

    Match[] public matches;

    //esta estructura nos permite conocer la opción elegida por cada jugador, para cada partido
    mapping(address => mapping(uint => uint8)) playerChoices;

    uint8 constant PAPER = 1;
    uint8 constant SCISSORS = 2;
    uint8 constant ROCK = 3;
    //esta variable nos permite hacer las consultas por id
    uint idCounter = 0;

    //esta función nos permite que un jugador desafíe a otro, conociendo su address. 
    function challengePlayer(address _enemyPlayer, uint8 _choice) external payable {
        require(_choice == ROCK || _choice == PAPER || _choice == SCISSORS, "Debes elegir entre las opciones validas");
        matches.push(Match(msg.sender,_enemyPlayer, msg.value, false, 0, block.timestamp));
        playerChoices[msg.sender][idCounter] = _choice;
        //atento a este evento, es el que nos devuelve el id para hacer la consulta
        emit NewGame(idCounter);
        idCounter++;
    }


    function acceptChallenge(uint8 _choice, uint _gameId) external payable {
        require(_choice == ROCK || _choice == PAPER || _choice == SCISSORS, "Debes elegir entre las opciones validas");
        require(msg.value == matches[_gameId].bet, "Debes apostar la misma cantidad que tu rival");
        require(playerChoices[matches[_gameId].playerTwo][_gameId] == 0, "Ya hiciste tu movimiento");
        playerChoices[msg.sender][_gameId] = _choice;
    }

    function _transferPrize(uint _gameId) private {
        require(matches[_gameId].wasTransfered == false && matches[_gameId].winner != 0, "Todavia no se obtuvieron los resultados, o el premio ya fue transferido");
        
        matches[_gameId].wasTransfered = true;

        if(matches[_gameId].winner == 1) {
            address payable to = payable(matches[_gameId].playerOne);
            to.transfer(matches[_gameId].bet * 2);
        }
        else if(matches[_gameId].winner == 2) {
            address payable to = payable(matches[_gameId].playerTwo);
            to.transfer(matches[_gameId].bet * 2);
        }
        else{
            //empate, se le devuelve el dinero a cada uno
            address payable to = payable(matches[_gameId].playerOne);
            address payable to2 = payable(matches[_gameId].playerTwo);
            to.transfer(matches[_gameId].bet);
            to2.transfer(matches[_gameId].bet);

        }
    }

    function evaluate(uint _gameId) external {
        
        uint8 choicePlayerOne = playerChoices[matches[_gameId].playerOne][_gameId];
        uint8 choicePlayerTwo = playerChoices[matches[_gameId].playerTwo][_gameId];

        require(choicePlayerTwo != 0, "Falta la eleccion del jugador 2");
        require(matches[_gameId].wasTransfered == false 
        && matches[_gameId].winner != 0,
         "El premio ya fue transferido");

        
        //empate
        if (choicePlayerOne == choicePlayerTwo) {
            matches[_gameId].winner = 250;
        }
        
        if (choicePlayerOne == ROCK && choicePlayerTwo == PAPER) {
            matches[_gameId].winner = 2;
        } else if (choicePlayerTwo == ROCK && choicePlayerOne == PAPER) {
            matches[_gameId].winner = 1;
        } else if (choicePlayerOne == SCISSORS && choicePlayerTwo == PAPER) {
            matches[_gameId].winner = 1;
        } else if (choicePlayerTwo == SCISSORS && choicePlayerOne == PAPER) {
            matches[_gameId].winner = 2;
        } else if (choicePlayerOne == ROCK && choicePlayerTwo == SCISSORS) {
            matches[_gameId].winner = 1;
        } else if (choicePlayerTwo == ROCK && choicePlayerOne == SCISSORS) {
            matches[_gameId].winner = 2;
        }
        _transferPrize(_gameId);
    }

    //Si pasó más de un minuto, se puede retirar el ether apostado
    function returnBet(uint _gameId) external {
        require(msg.sender == matches[_gameId].playerOne);
        require(block.timestamp >= matches[_gameId].timestamp + 1 minutes 
        && matches[_gameId].wasTransfered == false 
        && matches[_gameId].winner == 0, "La apuesta se puede retirar si paso mas de un tiempo predeterminado, y el adversario no participo");
        address payable to = payable(matches[_gameId].playerOne);
        matches[_gameId].wasTransfered = true;
        to.transfer(matches[_gameId].bet);
    }

}