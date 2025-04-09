# Tetris Duelistas

Um jogo de Tetris competitivo desenvolvido com Godot Engine para web, onde dois jogadores competem simultaneamente em uma batalha de blocos e estratégia.

## Sobre o Jogo

**Tetris Duelistas** é uma versão competitiva e dinâmica do clássico jogo Tetris, onde dois jogadores jogam simultaneamente, competindo para ver quem sobrevive mais tempo enquanto utiliza power-ups para dificultar o jogo do adversário.

![Screenshot do jogo](screenshot.png)

## Características Principais

- **Modo Competitivo 1v1:** Jogue localmente contra um amigo no mesmo teclado.
- **Sistema de Power-Ups:** Complete linhas para ganhar power-ups que podem ser usados estrategicamente.
- **Peças Especiais:** Chance de aparecer peças especiais que oferecem mais pontos ao serem usadas.
- **Interação Dinâmica:** As ações de um jogador afetam diretamente o jogo do outro.
- **Comandos Intuitivos:** Controles simples e familiares para quem já jogou Tetris antes.

## Power-Ups Disponíveis

- **Limpar Linhas:** Remove linhas aleatórias da grade do adversário.
- **Acelerar:** Aumenta temporariamente a velocidade de queda das peças do adversário.
- **Trocar Blocos:** Troca a sua peça atual com a do adversário.
- **Espelhar Controles:** Inverte temporariamente os controles direcionais do oponente.
- **Bomba Tetris:** Cria uma peça especial que, quando posicionada, explode e limpa uma área 3x3.

## Controles

### Jogador 1 (Lado Esquerdo)
- **A/D:** Mover peça para esquerda/direita
- **W:** Rotacionar peça
- **S:** Queda suave (soft drop)
- **Espaço:** Queda rápida (hard drop)
- **E:** Guardar peça (hold)
- **1, 2, 3:** Ativar os diferentes power-ups (quando disponíveis)

### Jogador 2 (Lado Direito)
- **Setas Esquerda/Direita:** Mover peça
- **Seta para Cima:** Rotacionar peça
- **Seta para Baixo:** Queda suave (soft drop)
- **Enter:** Queda rápida (hard drop)
- **Ctrl:** Guardar peça (hold)
- **Num 1, 2, 3:** Ativar os diferentes power-ups (quando disponíveis)

### Outros Controles
- **P/ESC:** Pausar o jogo

## Como Jogar

1. Complete linhas para marcar pontos e aumentar seu nível.
2. Quanto maior o nível, mais rápido as peças caem.
3. A cada 4 linhas completadas, você ganha um power-up aleatório.
4. Os power-ups ficam disponíveis nos slots numerados (1-3) e podem ser ativados a qualquer momento.
5. Use os power-ups estrategicamente para atrapalhar seu oponente ou melhorar sua situação.
6. Você pode armazenar até 3 power-ups diferentes ao mesmo tempo.
7. O último jogador a sobreviver vence!

## Sistema de Power-Ups

O sistema de power-ups é o diferencial do Tetris Duelistas:

1. **Medidor de Power-Up:** Completa-se ao fazer linhas.
2. **Ganho Automático:** Ao completar o medidor, você ganha um power-up aleatório.
3. **Armazenamento:** Os power-ups ficam nos seus slots numerados prontos para uso.
4. **Efeitos Visuais:** Quando um power-up é ativado, efeitos visuais indicam qual jogador foi afetado.
5. **Duração dos Efeitos:** Alguns power-ups têm efeitos instantâneos, outros duram por um tempo limitado.

## Recursos Técnicos

- Desenvolvido com Godot Engine 4.2
- GDScript para toda a lógica do jogo
- Interface otimizada para web
- Sistema de eventos para comunicação entre componentes
- Física e colisões personalizadas para o comportamento dos blocos

## Instalação e Execução

1. Clone este repositório
2. Abra o projeto no Godot Engine 4.2 ou superior
3. Execute o projeto no editor ou exporte para web

## Inspirações

Este jogo foi inspirado pelo clássico Tetris e outras versões competitivas como Tetris Battle e Puyo Puyo Tetris, com uma abordagem única no sistema de power-ups e mecânicas competitivas.

## Licença

Este projeto é licenciado sob a MIT License - veja o arquivo LICENSE para mais detalhes. # newtetris
