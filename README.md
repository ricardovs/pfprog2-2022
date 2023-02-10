# PFProg2-2022

## Introdução

Projeto Final apresentado na disciplina de Tópicos Especiais de Programação 2022/2.

## Especificação

### REQUISITOS DO PROJETO

1. Criar uma dApp com uma ou mais interfaces que ajudem o usuário a interagir com o contrato inteligente.
    - Esta dApp deve ser acessada via http em alguma das máquinas locais do Labgrad3 OU nuvem pública
    - O(s) contrato(s) deve(m) ser implantado(s) em uma rede de teste pública
    - Todos os códigos devem ser disponibilizados via github
2. O contrato inteligente deve usar *modifers* para testar a execução inicial de funções
3. Seu contrato deve emitir evento(s), e a sua interface deve capturar essse(s) evento(s) reagindo de alguma forma a ele(s)
    - INFORMAÇÕES ADICIONAIS
        - [Solidity - Events](https://www.w3schools.io/blockchain/solidity-events/)
4. Contract Factory
    - Seu contrato princial deve funcionar como um Contract Factory, sendo capaz de criar  novos contratos
    - Seu contrato principal deve Interagir com um dos contratos criados por ele
    - INFORMAÇÕES ADICIONAIS
        - Básico:
            - [INTERACT WITH OTHER CONTRACTS FROM SOLIDITY](https://ethereum.org/pt-br/developers/tutorials/interact-with-other-contracts-from-solidity/)
        - Avançado:
            - [How to Create a Smart Contract Factory in Solidity using Hardhat](https://www.quicknode.com/guides/smart-contract-development/how-to-create-a-smart-contract-factory-in-solidity-using-hardhat)
            - [Hardhat Tutorial](https://hardhat.org/tutorial)

#### REQUISITO EXTRA

- Utilizar alguma ferramenta de Unit test
    - INFORMAÇÕES ADICIONAIS
        - Básico (+10%): [Remix Unit testing plugin](https://remix-ide.readthedocs.io/en/latest/unittesting.html#)
        - Avançado (+20%): [Testing contracts with Hardhat/Mocha](https://hardhat.org/tutorial/testing-contracts)

### AVALIAÇÃO

O projeto será availiado com uma nota de 0 a 10 (que será a nota Pr definida no Programa da Disciplina), dividida de acordo com as seguintes entregas:

- **Entrega 1** : Descrição geral da DApp (Prazo: 22/dez) => **1 ponto**.
- **Entrega 2** : Contrato deployed em uma rede de teste + acesso http à DApp + Códigos implementados (Prazo: 30/jan.) =>  **8 pontos**.
    - _Obs : Caso você tenha utilizado alguma ferramenta de Unit Test, você deverá gravar um pequeno vídeo (2-3 min) demonstrando a realização dos testes_
- **Entrega 3** :  Apresentação (Prazo: 31/jan a 07/fev) => **1 ponto**.
    - _Obs : Além do ponto de apresentação no projeto, cada estudante poderá receber turings dos colegas como resultado da apresentação. Os turings recebidos serão contabilizados posteriormente_.

## Domínio de Aplicação

Trata-se de um jogo de adivinhar palavras, no qual um jogador Desafiante, libera uma lista de palavras para que os outros adivinhem qual palavra foi escolhida por ele.
Caso os jogadores desafiados acertem a palavra escolhida pelo desafiante, eles levam o premio. Do contrario, caso ninguém escolha a palavra correta, o desafiante leva tudo. A plataforma permite que o desafiante seja dono de um Jogo associado a uma palavra secreta. Durante o jogo, o dono deve publicar uma sequencia de palavras, que deve incluir a palavra secreta (caso o dono do jogo não libere a palavra secreta ele perde direito ao prêmio). 

Ao criar um jogo, o dono dele gasta tokens que são incluido ao premio final. Cada aposta também gasta tokens que se adicionam ao jogo. Caso mais de uma pessoa escolher corretamente a palavra secreta, o premio passa a ser dividido entre elas. Não há limite para o número de palavras que o dono do jogo pode liberar, porém cada nova pista (correta ou não) tem um custo para o dono do jogo. O jogo só acaba à pedido do dono peça, ou após certo tempo no qual nenhuma ação seja feita (isto é, caso ninguém aposte numa palavra e nem o dono do jogo libere uma dica).

Esse sistema se assenta sobre as seguintes premissas:  a palavra ser enviada secretamente no início do jogo, não pode ser adivinha pelos jogadores utilizando força-bruta ao longo de um jogo, nem pode ser trocada pelo dono após o inicio de um jogo. Uma das formas de atingir esses objetivos seria com transações privadas.

## Instalação

A DApp roda em um servidor Web, logo as seguintes bibliotecas serão necessárias:
```
npm install connect
npm install serve-static
npm install hardhat
```

Para compilar o código fazemos:
```
npx hardhat compile
```

Para rodar a rede de testes:
```
npx hardhat node
```

## Uso

Para executar o código basta rodar:
```
node app.js
```

Feito isso, você abrirá seu html no browser usando a url: [http://localhost:3000/index.html](http://localhost:3000/index.html).

## Suporte

Mande um e-mail para ric1500ric@gmail.com

## Licença

All other files are covered by the GNU license, see [`LICENSE`](./LICENSE).
