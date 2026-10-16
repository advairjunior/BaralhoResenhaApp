# Baralho da Resenha — o jogo da turma

Jogo de bebida para a turma de amigos, no estilo Eu Nunca / Quem é mais provável / Beba se,
com Tribunal, Correio anônimo, duelos e mímica. A turma é de casados, mas joga como amigos:
engraçado e constrangedor na medida, sem cartas que viram DR, com o nível ajustável.

Flutter Web/PWA + ASP.NET Core (.NET 10), na mesma estrutura do TocaEssaApp.
Cada pessoa joga no próprio celular pelo navegador, sem conta e sem instalar nada.

## Como funciona

1. Alguém cria a sala e recebe um código de 4 letras e um QR Code.
2. A turma entra pelo código ou pelo link, com nome e **selfie com careta** (a câmera
   sorteia um tema, como "cara de quem dormiu no sofá"). Quem joga sem álcool marca
   isso e conta pontos.
3. O anfitrião escolhe o nível e os modos e começa.
4. Todos veem a mesma carta ao mesmo tempo (tempo real por SSE).

### Jogos (um só ou misturados)

Na sala de espera (e a qualquer momento, pelo menu) quem criou a sala liga os jogos da noite.
Com **um** ligado, a noite é só ele. Com **vários**, as cartas vêm embaralhadas, com ritmo:
nunca o mesmo jogo três vezes seguidas, e cada jogo tem um peso (Eu Nunca 4, Quem é mais
provável 3, Beba se 3, Tribunal 3, Imagem e Ação 2, Rodada de Elogios 1, Correio 1, Casais em Jogo 1). A regra-relâmpago entra em cerca de 1 a cada 7 cartas.
A tela mostra o resumo: "🎯 Só Eu Nunca" ou "🎲 Misturando: …".


| Modo | Como joga |
|------|-----------|
| 🙊 Eu Nunca | Cada um responde em segredo. Quem já fez leva ponto. Virada: se a maioria já fez, leva quem nunca fez; se todo mundo fez, ninguém leva. Se só uma pessoa fez: "conta essa história!" Carta **🎤 Conta essa** (`"conta": true`): todo mundo que já fez conta a sua, um de cada vez, com a foto na tela e o "Contei" (quem criou a sala também passa a vez). |
| 👉 Quem é mais provável | A cada carta o jogo sorteia: 🗳️ votação no celular (tambor, foto e nome do mais votado; na revelação aparecem todos com os votos) ou 👉 todo mundo aponta no 3 (quem criou a sala puxa a contagem, que aparece junto em todos os celulares; depois toca na foto de quem foi apontado). Cerca de 1 em cada 3 cartas é duelo. Cartas 💛 de elogio são sempre votadas e o escolhido distribui goles em vez de beber. ⚔️ **Duelo**: {jogador} contra {jogador2} se apresentam (dancinha, piada, imitação, vendedor…), só o resto da turma vota, entre os dois, e quem perde leva o ponto (empate: os dois). ✊✋✌️ **Pedra, papel e tesoura**: os dois sorteados escolhem em segredo no celular, o app revela e quem perde leva (empate: jogam de novo). Prêmio Rei(nha) dos duelos. |
| ⚖️ Tribunal da Turma | "{jogador} tem cara de…?": a turma vota 👍/👎 em segredo, o réu só espera; suspense com a foto. Na zoeira, maioria sim (empate também) condena e o réu leva ponto. Na carta de elogio é ao contrário: maioria não condena; maioria sim (ou empate) faz o réu distribuir goles. Placar sem dizer quem votou. |
| ⭐ Jurados | O app elege alguém e o resto dá nota de 1 a 5 estrelas, em segredo ("o quanto {jogador} se veste bem?"). Média 4 ou mais: aprovado(a), distribui goles e ganha carta na manga; média 2 ou menos: reprovado(a), leva 1 ponto. As notas aparecem sem dizer quem deu qual. Cartas com id `ju-`. |
| 🎵 Roda de Música | A carta dá o tema ("abertura de novela", "pagode dos anos 90") e o app sorteia a ordem: cada um canta na sua vez, com a foto na tela, e toca em "Cantei". Travou ou repetiu, quem criou a sala marca "Travou" e a pessoa leva 1 ponto. Cartas com id `mu-`. |
| 💛 Rodada de Elogios | Dinâmicas de elogio para alguém da mesa. Ninguém bebe. |
| 📮 Correio da Resenha | Uma pessoa fica de fora ("aguarde…") e o resto escreve um bilhete anônimo de até 20 letras sobre ela, guiado pela carta (apelido, superpoder, mania…). Com todos escritos (ou pelo menos 2, se quem criou a sala revelar antes), todos os celulares mostram a foto e os bilhetes embaralhados, sem autor. Quem está na foto escolhe o favorito ⭐. Ninguém bebe; precisa de 4 pessoas. |
| 🎭 Imagem e Ação | Mímica. Só quem faz a mímica vê a palavra; a turma vê a dica (categoria e número de palavras). O formato depende da mesa: até 5 pessoas, uma faz para todos; de 6 a 8, dois times; 9 ou mais, três, com os mímicos fazendo a mesma palavra ao mesmo tempo. Times sorteados a cada carta, mímico em rodízio, cronômetro de 60 s. Quem criou a sala marca quem acertou: time que perde leva ponto; ninguém acertou, os mímicos levam. Prêmio Artista da mímica. |
| 🍺 Beba se | Carta para a mesa. Cada um marca "Me pegou!" ou "Não". |
| ⚡ Regra-relâmpago | Regra temporária que vale pelas próximas 3 cartas. Regra que depende de alguém falar traz uma **isca**, para não ser desperdiçada. A carta da regra só apresenta ("Ana entrevista Beto"); depois as iscas vêm intercaladas, uma carta comum e uma **⚡ vez da regra**, 3 vezes: 🎤 entrevista (quem só pode falar cantando é entrevistado(a) por alguém sorteado, com perguntas do app), 🎤 pergunta-isca para a mesa (ex.: na regra "proibido falar de trabalho", "Como anda o trabalho?"), 😂 missão para fazer alguém rir, ❓ perguntas para o Mestre das Perguntas e 🥁 piada ruim para o piadista. Quem criou a sala marca **🚨 quem vacilou** (+1 ponto; prêmio Vacilão(ona) da regra). Iscas em `Dados/iscas.json`. |
| 💞 Casais em Jogo | Um do casal escreve a verdade sobre si, o par tenta adivinhar; quem respondeu julga. Errou, o palpiteiro bebe. Os casais se revezam. **Começa desligado**; ligado, aparece de vez em quando, como tempero. Os pares são marcados na sala de espera. |

**Cronômetro:** carta que fala em "N segundos" (e a mímica, com 60 s) tem cronômetro sincronizado: quem criou a sala dá o "valendo" e todos os celulares contam o mesmo tempo (de novo, recomeça).

**Dose de verdade:** a carta que diz "bebe 2" (`"goles": 2`) é gole de verdade, fora do cofrinho, com o selo "🍺 DOSE DE VERDADE". As outras somam ponto no cofrinho.

**Votação não é Beba se:** carta que pede para a turma votar ou decidir é sempre votação no celular (Quem é mais provável, Duelo ou Tribunal), nunca Beba se.

**Ritmo da bebida (cofrinho de goles):** cada vez que a carta pega alguém vale 1 ponto; o gole só sai quando o cofrinho enche: 🐢 Devagar (1 gole a cada 7 pontos, o padrão), 🚶 Normal (a cada 2) ou 🔥 Raiz (todo ponto é gole). Quem criou a sala também ajusta o tamanho do cofrinho no − e +, de 1 a 20 pontos, até no meio do jogo. A tela avisa "🍺 Cofrinho cheio! Fulano bebe agora." e o placar mostra goles e cofrinho. No elogio, o número de goles distribuídos também cai.

**⏩ Passar a carta sozinho** (ligado por padrão): quando todo mundo responde (no Beba se, "Me pegou" ou "Não") e quem tem alguma coisa pendente confirma ("🍺 Bebi", "🎤 Contei", "💛 Distribuí", "📮 Li tudo"), a próxima carta vem em 3 segundos, sem depender de quem criou a sala. Sem pendência, a contagem começa na revelação (nas votações e no Tribunal, depois do suspense). Regra-relâmpago, rodada de elogios e aponta no 3 pedem "Pronto ✓" de todo mundo. Qualquer um toca em "⏸️ Segura aí" para segurar; aí só quem criou a sala passa.

**Quem manda nas cartas:** só quem criou a sala puxa a próxima carta, pula, revela antes da hora e usa o "Tira essa". Os outros veem "Esperando Fulano puxar a próxima carta".

### 🃏 Cartas na manga (estilo Uno)

Cada um começa a noite com uma carta na manga e guarda até 3. Ganha mais quem vence duelo ou pedra, papel e tesoura, o time que acerta a mímica, quem a turma escolhe no elogio e, a cada 10 cartas, quem está há mais tempo sem ganhar. A mão é segredo: a turma só vê quantas cada um tem.

| Carta | O que faz |
|---|---|
| 🛡️ Escudo | Cancela o que a carta da mesa fez com você. |
| 🎯 Passa a bola | O que a carta fez com você vai para quem você escolher. |
| ↩️ Devolve | No duelo, o ponto volta para quem te venceu. |
| 🥔 Batata quente | Vira dose com +1 gole em quem você escolher; a pessoa pode passar adiante com a dela. |
| ✖️2 Dobra | Dobra o que a carta fez com outra pessoa. |

Uma por pessoa a cada carta da mesa; todos os celulares mostram quem usou o quê. Prêmio "🃏 Mestre das cartas na manga". Dá para desligar na configuração.

### O jogo se explica sozinho

Ninguém precisa ensinar ninguém: embaixo de toda carta tem **ⓘ Como joga** com as regras daquele jogo (e de cada jeito dele: votação, aponta no 3, duelo, pedra-papel-tesoura, mímica com times ou não), os pontos e goles do ritmo da noite e quem passa as cartas. Na primeira vez que um jogo aparece no celular, uma faixa "💡 Primeira vez de…" convida a ver. Tocar numa carta na manga abre a ficha (o que faz, quando dá para usar, exemplo e se vale agora), e "ⓘ Como funcionam" mostra todas e como ganhar mais. A sala de espera e o menu têm "Como funciona o jogo".

### Noites prontas

Na sala de espera, um toque monta a noite: 🍻 Resenha clássica, 🌡️ Esquenta até o Picante, 🎭 Noite das brincadeiras, 😂 Só zoeira, 💛 Noite tranquila e 🔥 Raiz (pede confirmação). A noite escolhida aparece marcada; mexer em qualquer coisa embaixo vira noite personalizada.

### Níveis

🧃 Leve · 🍺 Resenha (padrão) · 🌶️ Picante · 🔥 Baralho Original (pede confirmação).
Cada nível inclui os de baixo, mas pouco: 85% das cartas são do nível escolhido, e o que vem de baixo são só as cartas marcadas como destaque (`"destaque": true`), as melhores do nível. Leve não é infantil: é humor de adulto sem malícia.

**🌡️ Esquenta sozinho** (opcional): a noite começa no Leve e sobe um nível a cada 8 cartas,
até o nível escolhido. Esquentando, 85% das cartas são do nível do momento e o resto só das
destaque do nível logo abaixo, para não voltar ao começo. A barra embaixo da carta mostra o nível e quando
esquenta, e a primeira carta do nível novo avisa "🌡️ Esquentou!".

**👎 Tira essa:** quem criou a sala tira a carta da mesa (com confirmação). Ela sai do baralho daquela
noite, vem outra no lugar e a turma vê quem tirou. Quem tira muitas leva o prêmio "👮 Fiscal da resenha".

A **Zona Segura** (ligada por padrão) tira as cartas marcadas `"sensivel": true`,
sobre ex, ciúme e traição.

## Durante e depois do jogo

- **Suspense na votação:** na Votação, tambor 🥁, "e o mais votado é…" e a foto gigante de quem a turma escolheu.
- **Selfie de reação:** quem foi pego na carta (bebeu, conta a história, casal da vez) tira uma selfie com tema na hora da revelação; ela vai para o **mural da noite**.
- **Fim da noite:** quem criou a sala encerra e todos veem os **Prêmios da Noite** (Rei(nha) da noite, Alvo preferido, Xodó da turma, Contador(a) de histórias, Já fez de tudo, Santo(a), Artista da mímica, Rei(nha) dos duelos, Vacilão(ona) da regra, Fiscal da resenha, Casal em sintonia, Casal que precisa conversar), o resumo e o mural. As fotos do mural **não ficam guardadas**: cada um escolhe as que quer ("Só as minhas", uma a uma ou todas) e salva no próprio celular antes de a sala fechar. O cartão dos prêmios vira imagem para mandar no grupo. "Só mais uma rodada" volta ao jogo com o placar mantido.

## Cartas

Todas ficam em `servidor/BaralhoResenhaApp.Api/Dados/cartas.json`, embutidas na DLL.
Para incluir uma carta, acrescente uma linha com `id` novo e único, `modo`, `nivel`
e `texto`. `{jogador}` e `{jogador2}` no texto viram nomes de pessoas diferentes da sala.

Campos opcionais: `sensivel` (Zona Segura esconde), `elogio`, `duelo`, `destaque` (das melhores
do nível), `categoria` (Imagem e Ação), `isca` e `iscas` (regras-relâmpago).
Perguntas, missões e piadas das iscas ficam em `Dados/iscas.json`.
Testes conferem se não há id repetido, se todo jogo tem cartas Leve e se todo nível tem cartas.

As cartas passam por uma página de revisão (manter, cortar ou mudar), gerada a partir destes arquivos.

## Salas

As salas ficam **na memória** do servidor: somem depois de 12 horas paradas, quando
o último jogador sai ou quando há um novo deploy. Não existe banco de dados nesta fase.

## Selfies

- A câmera é a mesma do TocaEssa (`camera_do_app.dart` e `camera_do_cartao.dart`,
  copiadas só com as cores trocadas). Sem permissão de câmera, cai na câmera do celular.
- O app recorta exatamente o círculo da moldura e manda um JPEG de 360×360 (poucos KB),
  pelo canvas do navegador (`reduzir_selfie_web.dart`).
- A foto fica na memória junto com a sala (sem R2) e é servida em
  `/api/salas/{codigo}/fotos/{id}`; cada foto nova ganha outro id.
- A selfie é opcional (pede uma vez); na sala de espera, tocar na própria foto troca.

## Executar localmente

```powershell
.\rodar.ps1
```

Sobe a API na porta 5090 e abre o Flutter no Chrome (porta 5183).

## Testes

```powershell
dotnet build BaralhoResenhaApp.sln
dotnet test BaralhoResenhaApp.sln --no-build
cd cliente; dart analyze; flutter test
```

## Deploy no Render

Mesmo modelo do TocaEssa: `Dockerfile` + `render.yaml` com deploy automático a cada
push na `main`. Plano gratuito, sem banco e sem variáveis secretas.

1. No Render: **New → Blueprint**, escolha o repositório `advairjunior/BaralhoResenhaApp`.
   O `render.yaml` cria o serviço `baralho-resenha`.
2. Confira `https://<serviço>.onrender.com/api/saude`.

Passo a passo e smoke test em [`docs/DEPLOY_RENDER.md`](docs/DEPLOY_RENDER.md).
Não faça deploy durante uma noite de jogo: as salas ficam em memória e caem no reinício.

No plano gratuito o serviço dorme depois de 15 minutos sem uso: a primeira pessoa a
abrir espera uns 30 a 60 segundos. Durante o jogo a conexão de tempo real o mantém acordado.

## Guia para a turma

[`/como-jogar`](https://baralho-resenha.onrender.com/como-jogar): o link para mandar no grupo, com como começa, uma rodada passo a passo, todos os jogos com telas reais, pontos e goles, cartas na manga e fim da noite. O botão "📖 Como jogar?" da tela inicial abre o mesmo guia. Toda novidade que a turma vê atualiza o guia ([`docs/GUIA_COMO_JOGAR.md`](docs/GUIA_COMO_JOGAR.md)).

## Documentação

- [`CLAUDE.md`](CLAUDE.md) e [`.claude/rules/`](.claude/rules): regras de trabalho, segurança e convenções.
- [`docs/claude/CONTEXTO_ATUAL.md`](docs/claude/CONTEXTO_ATUAL.md): arquitetura e decisões de produto.
- [`docs/claude/COMO_CONTINUAR.md`](docs/claude/COMO_CONTINUAR.md): como retomar o projeto numa conversa nova.

## Próximas ideias

- Esquenta começando no Resenha; noites prontas (presets); peso por jogo; velocidade do esquenta.
- Cartas da turma: piadas internas e palavras de mímica salvas para o grupo.
- Mural permanente ("Memórias da Resenha"), para rever as noites anteriores.

As duas últimas precisam guardar dados além da noite: banco (PostgreSQL no Render) e fotos no R2, como no TocaEssa.
