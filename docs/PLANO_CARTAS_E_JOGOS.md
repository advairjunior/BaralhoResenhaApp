# Plano: cartas que prendem a mesa, rodízio sem quem caiu e dois jogos novos

> Escrito em 2026-10-28, tudo aprovado pelo proprietário. Cada etapa nasce de um teste que
> falha (quando há comportamento novo), vira um commit e, quando a turma vê a mudança, atualiza
> o guia `/como-jogar` e o "ⓘ Como joga" na medida da importância (`docs/GUIA_COMO_JOGAR.md`).

## Já feito em 2026-10-28

- **Limpeza do baralho** (`78c2b48`): saíram 75 cartas sem graça (fato sem história, coisa que
  todo mundo já fez, repetidas) e entraram 15 Leve de segredo e lembrança da turma
  (`en-187`…`en-191`, `bs-130`…`bs-139`). Os ids cortados estão na mensagem do commit.
- **Fora do plano:** cartas escritas a partir das histórias da turma (piadas internas, palavras
  de mímica da turma). O baralho fica com cartas que funcionam para qualquer turma.

## O que prende a mesa

As cartas novas seguem quatro gatilhos, e toda carta nova daqui em diante deveria ter pelo
menos um deles:

1. **História puxada:** a carta acaba numa história que a turma quer ouvir ("🎤 Conta essa").
2. **Suspense:** o segredo só aparece na revelação (Tribunal, Jurados, votação).
3. **Lembrança da turma:** fala desta mesa, sem precisar de história escrita antes.
4. **Volta mais tarde:** a regra ou o bilhete continua valendo depois que a carta passa.

---

## Etapa 1: cartas novas (só dados) — feito em 2026-10-28

Entram em `servidor/BaralhoResenhaApp.Api/Dados/cartas.json`, cada uma perto das irmãs do mesmo
jogo. Os ids abaixo foram conferidos no histórico: nunca foram usados (a página de revisão guarda
decisões por id, e um id reaproveitado herdaria a decisão antiga).

| Id | Jogo | Nível | Texto | Marcas |
|---|---|---|---|---|
| `en-192` | Eu Nunca | Resenha | Eu nunca contei uma história para esta turma que não foi bem do jeito que aconteceu. | `conta` |
| `bs-140` | Beba se | Resenha | {jogador} conta a primeira impressão que teve de alguém da mesa, sem dizer quem é. Se a turma adivinhar quem é, {jogador} bebe 2. | `goles: 2` |
| `bs-141` | Beba se | Leve | Bebe quem não lembra onde foi o primeiro encontro desta turma inteira junta. A turma confere! | |
| `bs-142` | Beba se | Leve | {jogador} imita a risada de alguém da mesa. Se a turma acertar quem é, essa pessoa bebe; se ninguém acertar, {jogador} bebe. | |
| `mp-187` | Quem é mais provável | Resenha | Quem desta mesa guarda o maior segredo sobre outra pessoa da mesa? | |
| `tr-081` | Tribunal | Resenha | {jogador} já falou mal desta festa no caminho de volta para casa? | |
| `tr-082` | Tribunal | Leve | {jogador} sabe o nome completo de todo mundo desta mesa? Se a turma disser não, {jogador} prova na hora! | |
| `tr-083` | Tribunal | Leve | {jogador} lembra o que vestia na última festa da turma? A turma confere nas fotos! | |
| `el-025` | Elogios | Leve | Cada um diz há quanto tempo conhece {jogador} e onde foi a primeira vez que se viram. | |
| `co-031` | Correio | Leve | A primeira lembrança que você tem de {jogador}. | |
| `co-032` | Correio | Resenha | Uma previsão para {jogador} sobre o resto desta noite. | |
| `rr-056` | Regra-relâmpago | Resenha | Quem disser "lembra quando…" tem que contar a história até o fim. Parou no meio, bebeu. | |
| `rr-057` | Regra-relâmpago | Leve | {jogador} escolhe em segredo uma palavra proibida e conta só para quem está à direita. Quem falar a palavra bebe, e os dois revelam qual era quando a regra acabar. | |
| `rr-058` | Regra-relâmpago | Resenha | {jogador} é o(a) detetive: pode apontar quem está aumentando uma história. Se a pessoa confessar, ela bebe; se não, {jogador} bebe. | |

Cuidados:
- O Correio aceita bilhetes de até 20 letras: conferir que "previsão" e "primeira lembrança"
  cabem bem nesse limite. Se ficar apertado, a carta vai para o ✍️ Termine a frase (Etapa 3).
- Nada aqui é votação dentro do Beba se (`bs-140` e `bs-142` são adivinhação em voz alta).
- Verificação: `BaralhoTestes` (carrega sem id repetido; o Leve tem carta para uma noite).
- Depois: publicar as cartas na página de revisão como 🆕, para o proprietário marcar.
- Commit: `feat: 14 cartas que puxam história, segredo e lembrança da turma`.

## Etapa 2: o rodízio não chama quem caiu — feito em 2026-10-28

Hoje o rodízio do `{jogador}` (`Sala.Distribuir`) pode chamar alguém que está sem sinal, e a carta
fica esperando a pessoa (réu do Tribunal, quem abre a Roda de Música, a pessoa do Correio).

1. **RED** em `RodizioTestes`: com um jogador sem sinal há mais de `TempoParaCair`, ele nunca é o
   `{jogador}` nem o `{jogador2}` e não ganha `Chamadas`.
2. **GREEN:** em `Distribuir`, ordenar só os `Conectado(j)`; se não sobrar ninguém conectado (caso
   raro, todos caíram), usar a mesa inteira como hoje.
3. Quem volta continua na volta do rodízio: as `Chamadas` ficam no jogador, que é o mesmo ao
   voltar com o mesmo nome. Teste: quem volta é chamado na volta atual, se ainda não foi.
4. Guia: acrescentar "Quem caiu não é chamado até voltar" na linha "Todo mundo tem a sua vez".
5. Commit: `feat: o rodízio pula quem caiu da sala`.

## Etapa 3: ✍️ Termine a frase (jogo novo) — feito em 2026-10-28

Feito como abaixo, com uma diferença: peso 1, não 2 (com 2, a Imagem e Ação caía abaixo de
1 em 8 cartas; quem quiser mais Termine a frase põe no Muito).

O mais simples dos dois jogos: reaproveita o anonimato do Correio. A especificação de produto
está em `docs/PLANO_RECONEXAO_TV_JOGOS.md` (Etapa 3); aqui fica o como fazer.

1. **Servidor**
   - `ModoDeJogo.TermineAFrase`; peso 2 em `Baralho.Pesos`; precisa de 3 pessoas ou mais.
   - `Sala.TermineAFrase.cs`: `Completar(token, rodada, texto)` (até 40 letras, uma por pessoa),
     `VotarNaFrase(token, rodada, indice)` (não vale votar na própria; o servidor sabe de quem é
     cada frase, a tela não).
   - Fases dentro da carta: escrevendo → votando (frases embaralhadas, sem autor) → revelada.
     Passa para votando quando todos os conectados escreveram.
   - Revelação: a mais votada mostra o autor, que distribui goles ou ganha carta na manga; as
     outras continuam anônimas. Empate: todos os mais votados.
   - Testes (RED antes de cada parte): limite de 40 letras; autor nunca sai na visão antes da
     revelação; não vota na própria; empate; só a vencedora revela o autor; quem caiu não trava.
2. **Cartas** `tf-001`… : 30 começos (12 Leve, 12 Resenha, 6 Picante), no tom da turma.
   Exemplos: "O pior lugar para um primeiro encontro é…", "A desculpa mais fraca para sair
   mais cedo de uma festa é…", "O que esta turma vai estar fazendo daqui a 20 anos:…".
3. **App:** tela em `cliente/lib/telas/termine_a_frase.dart` (campo com contador de letras,
   lista para votar, revelação com a foto do autor da vencedora). Testes com `ServidorFalso`.
4. **Ajuda e guia:** "ⓘ Como joga" do modo, cartão em "Os jogos" do `/como-jogar` com captura
   nova (roteiro em `ferramentas/guia/capturar.mjs`), linha na página de revisão.
5. Commits: `feat: jogo novo, ✍️ Termine a frase` e `docs: captura do Termine a frase`.

## Etapa 4: 🤥 Duas verdades e uma mentira (jogo novo)

Especificação em `docs/PLANO_RECONEXAO_TV_JOGOS.md` (Etapa 3).

1. **Servidor**
   - `ModoDeJogo.DuasVerdades`; peso 2; 3 pessoas ou mais.
   - A pessoa da vez sai do rodízio (Etapa 2 já garante que está conectada).
   - `Sala.DuasVerdades.cs`: `EscreverFrases(token, rodada, frases[3], mentira)` só para a pessoa
     da vez (até 60 letras cada); `VotarNaMentira(token, rodada, indice)` para os outros.
   - As frases aparecem para a mesa depois de escritas; qual é a mentira só sai na revelação.
   - Pontos: quem acertou escapa, quem errou leva ponto (`Pegar`); ninguém acertou → a pessoa
     da vez distribui. Prêmio novo em `PremiosDaNoite`: "🎭 Mentiroso(a) de respeito".
   - Se a pessoa da vez cair antes de escrever, quem está no comando vê "Fulano caiu: pular
     a carta?" (mesmo caminho da Etapa 1 da reconexão).
   - Testes (RED antes de cada parte): só a pessoa da vez escreve; a mentira não aparece em
     nenhuma visão antes da revelação; pessoa da vez não vota; pontos de acerto e erro;
     ninguém acertou; prêmio.
2. **Cartas** `dv-001`… : 20 temas (viagens, comida, infância, trabalho, festas da turma…),
   com Picante para "primeiros encontros" e "micos de casal" (sem virar DR).
3. **App:** `cliente/lib/telas/duas_verdades.dart` (três campos e a marca da mentira para a
   pessoa da vez; três botões para votar; revelação com a mentira riscada).
4. **Ajuda e guia:** "ⓘ Como joga", cartão e captura no `/como-jogar`, prêmio novo na seção
   "Fim da noite".
5. Commits: `feat: jogo novo, 🤥 Duas verdades e uma mentira` e `docs: captura do Duas verdades`.

## Etapa 5: conferir no celular o que a API não confere

Do smoke test de 2026-10-28 ficaram de fora, por precisarem de celular: selfie aparecendo no
outro aparelho e o mural no fim da noite. Conferir na próxima noite, junto com o peso por jogo e
o rodízio, e ver no log do Render se o servidor ficou acordado na pausa (`MantemAcordado`).

## Ordem

1. Etapa 1 (cartas) e Etapa 2 (rodízio sem quem caiu): pequenas, entram juntas antes da
   próxima noite.
2. Etapa 3 (Termine a frase).
3. Etapa 4 (Duas verdades).
4. Etapa 5 na noite seguinte a cada entrega.

Cada etapa: testes completos do servidor e do cliente, conferência no navegador na porta 5091,
commit atômico, e push só com autorização.
