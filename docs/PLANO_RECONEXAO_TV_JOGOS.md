# Plano: reconexão, Modo TV e jogos novos

> Escrito em 2026-10-18. Cada etapa nasce de teste que falha, vira um commit e,
> quando a turma vê a mudança, atualiza o guia `/como-jogar` e o "ⓘ Como joga".

## Já feito: voltar para a sala com o mesmo nome

Na noite de teste, um jogador caiu da sala e, ao entrar de novo, a sala recusou o nome
("Já tem alguém com esse nome"). Ele virou "Fabricio 2" e o primeiro Fabricio ficou parado,
sem ninguém para responder por ele.

Agora (`Sala.Entrar`):

- cada consulta ou ação do celular atualiza `Jogador.UltimoSinal`;
- quem entra com um nome que já está na sala **e está sem sinal há 20 s** volta a ser a mesma
  pessoa: mesmos pontos, goles, cartas na manga, foto e o comando da sala, se era quem criou.
  O celular antigo deixa de valer;
- se o dono do nome ainda está jogando, a entrada é recusada com uma mensagem que explica o que
  fazer;
- acento e maiúscula não criam outra pessoa ("Fabrício" = "fabricio").

Testes: `VoltarParaASalaTestes`.

---

## Etapa 1: reconexão sem susto (ideia 6)

Objetivo: ninguém trava a mesa por ter caído, e quem caiu sabe o que está acontecendo.

1. **Quem está conectado (servidor)**
   - `JogadorVisivel` ganha `Conectado` (sinal há menos de `TempoParaVoltar`).
   - Teste: jogador sem sinal aparece como desconectado na visão dos outros.
2. **A mesa não espera quem caiu (servidor)**
   - `RevelarSeTodosResponderam` e o "passar sozinho" (`ConferirProntos`) contam só quem está
     conectado. Quem caiu e volta no meio da carta ainda pode responder antes da revelação.
   - Cuidado com quem é a pessoa da carta (réu do Tribunal, mímico, quem está no Correio,
     a vez na Roda de Música): se ela cair, a carta continua esperando e quem criou a sala vê
     "Fulano caiu: pular a carta?".
   - Testes: carta revela sem o desconectado; carta do desconectado não passa sozinha.
3. **Tirar da sala (servidor + app)**
   - Quem criou a sala pode tirar um jogador desconectado (com confirmação), para o caso de
     alguém ir embora de vez. O placar dele some dos prêmios.
   - Rota nova `DELETE /api/salas/{codigo}/jogadores/{id}`, só para quem criou a sala e só para
     quem está desconectado. Testes de permissão: outro jogador não tira ninguém.
4. **No app**
   - Foto de quem caiu fica apagada, com 📵, na lista de jogadores e no placar.
   - Quando a consulta falha por rede (não por 401/404), aparece a faixa
     "Sem conexão, tentando voltar…" e o app tenta de novo sozinho. Hoje a falha de rede é
     silenciosa.
   - Na tela de entrada, quando a sala recusa o nome por estar em uso, botão "Tentar de novo".
5. **Guia:** uma linha em "Dúvidas" explicando que, se cair, basta entrar com o mesmo nome.

## Etapa 2: Modo TV, opcional (ideia 7)

Objetivo: com TV ou notebook por perto, a carta aparece grande para todo mundo. Sem TV, nada
muda: os celulares continuam mostrando tudo como hoje.

1. **Tela da TV (servidor)**
   - Quem criou a sala toca em "📺 Mostrar na TV" no menu. O servidor gera um token de **tela**:
     não é jogador, não responde, não entra no placar nem nos prêmios.
   - `Visao` para a tela: só o que está na mesa (carta, quem respondeu sem dizer o quê, a
     revelação, o placar, o mural). Nunca a mão de cartas na manga, a palavra da mímica nem
     resposta secreta antes da revelação.
   - Testes: a tela não aparece em `Jogadores`; não vê a palavra da mímica; não conta para
     "todos responderam"; token de tela não consegue agir.
2. **Pareamento**
   - O menu mostra um código curto e um QR. Na TV, abre-se `/tv` e digita o código, ou o
     notebook lê o QR. Sem login e sem instalar nada.
3. **Layout da TV (app)**
   - Rota `/tv/{codigo}`: carta enorme, fotos de quem já respondeu, contagem do cronômetro,
     tambor da votação e revelação em tela cheia, placar ao lado. Fonte grande, tema escuro.
   - Com a TV ligada, o celular pode mostrar a carta menor e destacar só os botões de responder
     (opção "Carta só na TV", desligada por padrão).
4. **Guia:** seção curta "Tem TV?" com uma captura da tela da TV.

Risco: o Render free dorme. A TV deve mostrar "acordando o baralho…" em vez de erro.

## Etapa 3: jogos novos (ideia 9)

Os dois seguem o padrão dos jogos atuais: `ModoDeJogo` novo, cartas em `cartas.json`, arquivo
parcial `Sala.<Jogo>.cs`, tela em `cliente/lib/telas/`, peso na mistura, "ⓘ Como joga" e seção no
guia com captura.

### 🤥 Duas verdades e uma mentira

- O app sorteia a pessoa da vez. Ela escreve no celular três frases curtas sobre si e marca
  qual é a mentira. A carta dá o tema ("viagens", "comida", "infância").
- A turma vota em segredo na mentira. Na revelação: as três frases, os votos e a mentira.
- Quem acertou escapa; quem errou leva ponto. Se ninguém acertou, a pessoa da vez distribui.
- Prêmio novo: "🎭 Mentiroso(a) de respeito" (mais rodadas sem ninguém acertar).
- Peso 2 na mistura. Testes: só a pessoa da vez vê o que escreveu antes da revelação; votação
  secreta; pontos por acerto e erro; pessoa da vez desconectada (ver Etapa 1).

### ✍️ Termine a frase

- A carta traz o começo ("O pior lugar para um primeiro encontro é…"). Cada um completa no
  celular, anônimo, com até 40 letras (o Correio usa 20).
- As respostas aparecem embaralhadas e todo mundo vota na melhor (não vale votar na própria).
- A mais votada revela o autor e ele distribui goles ou ganha carta na manga. As outras ficam
  anônimas.
- Peso 2. Testes: anonimato até a revelação; não vota na própria; empate; limite de letras.

## Ordem sugerida

1. Etapa 1 inteira, antes da próxima noite com a turma, porque foi o que travou o jogo.
2. Um jogo novo (Termine a frase é o mais simples: reaproveita o Correio).
3. Modo TV.
4. O outro jogo.
