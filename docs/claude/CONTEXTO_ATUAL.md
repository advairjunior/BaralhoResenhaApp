# Baralho da Resenha — Contexto atual

> Atualizado em: 2026-10-28

## O que é

Jogo de festa para a turma de amigos do proprietário (todos casados, jogando como amigos):
cada um no seu celular, cartas no estilo "Eu nunca" / "Beba se", com nível configurável.
O objetivo é resenha: engraçado, sem baixaria e sem virar DR de casal.

## Arquitetura

| Camada | Tecnologia |
|--------|-----------|
| Cliente | Flutter Web / PWA (publicado dentro da API, em `wwwroot`) |
| Servidor | ASP.NET Core Minimal APIs (.NET 10) |
| Estado | Salas em memória, sem banco; fotos também em memória |
| Tempo real | SSE (`/api/tempo-real/{codigo}`) + consulta a cada 6 s como reserva |
| Deploy | Render (Docker, plano free) — automático via push na `main` |

## Como uma noite funciona

```
Sala (código de 4 letras + QR)
├── Jogadores (token no aparelho, selfie opcional, "sem álcool" opcional)
├── Configuração (nível, jogos na mistura, Zona Segura, Esquenta sozinho, ritmo da bebida)
├── Rodada (uma carta por vez; só quem criou a sala puxa, pula, revela e tira)
│   ├── Respostas secretas → revelação
│   ├── Regra-relâmpago ativa (com isca e vacilo)
│   └── Momentos (selfie de reação para o mural)
└── Fim da noite (prêmios, resumo, mural para salvar no celular, "só mais uma")
```

## Jogos

Eu Nunca · Quem é mais provável (votação no celular ou aponta no 3; elogio; ⚔️ duelo) ·
Beba se · Regra-relâmpago (com iscas: entrevista, pergunta, missão, Mestre, piada; 🚨 vacilo) ·
Tribunal da Turma · Rodada de Elogios ·
Correio da Resenha (bilhetes anônimos de até 20 letras) · Imagem e Ação (1 mímico até 5 pessoas,
2 times de 6 a 8, 3 times com 9+) · Jurados · Roda de Música · Impostor (palavra para todos menos
um, que só sabe o tema; pistas em voz alta na ordem do app; voto secreto; 4+ pessoas) ·
Termine a frase (cada um completa o começo da carta em segredo, a turma vota sem saber de quem é; 3+ pessoas) ·
Duas verdades e uma mentira (a pessoa da vez escreve três frases sobre si e a turma vota na mentira; 3+ pessoas) ·
Chuta aí (pergunta com resposta em número; mais longe leva, mais perto distribui) ·
Batata quente (categoria; cada um fala e toca em "Falei!"; o pavio escondido é do servidor e estoura sozinho) ·
Isso ou aquilo (duas opções, voto secreto; a minoria leva; empate ou unanimidade, ninguém; 3+ pessoas) ·
Quem sou eu? (todo mundo vê o segredo, menos a pessoa da vez, que só sabe a categoria; pergunta sim ou não
em 90 s; acertou, carta na manga; o tempo acabou, ponto; quem criou a sala marca) ·
Palavra proibida (a mímica falada: quem explica vê a palavra e 4 proibidas; mesmos times, 60 s e
resultado da mímica, mas não conta para o prêmio de artista da mímica; 3+ pessoas) ·
Quem escreveu? (pergunta pessoal; cada um responde em segredo, uma resposta vai para o centro e todos votam
no autor, até ele; errou, ponto; ninguém acertou, o autor escapa com carta na manga; 3+ pessoas).

## Regras de produto já decididas

- **Cofrinho de goles:** cada vez que a carta pega alguém vale 1 ponto; o gole só sai quando o
  cofrinho enche (Devagar 7, Normal 2, Raiz 1). Padrão: Devagar.
- **Eu Nunca com virada:** todo mundo fez, ninguém leva; a maioria fez, leva quem nunca fez.
- **Passar sozinho:** todo mundo respondeu e as pendências (beber, contar a história, distribuir, ler o correio) foram confirmadas, a carta passa em 3 s (qualquer celular pede, o servidor passa uma vez); "Segura aí" para. A contagem é recalculada a cada ação (`Tocar` chama `ConferirProntos`).
- **Vacilo:** em regra de entrevista ou risada, só a pessoa da regra pode vacilar.
- **Níveis:** 85% das cartas são do nível escolhido; o que vem de baixo são só as cartas `destaque`.
- **Leve não é infantil:** humor de adulto sem malícia.
- **Votação nunca é Beba se:** vira votação no celular, duelo ou tribunal.
- **Dose de verdade:** carta com `goles` ("bebe 2") é gole direto, fora do cofrinho (`Punir`/`Perdoar`).
- **Cronômetro sincronizado:** o servidor guarda o fim; cada celular conta a partir do que falta.
- **Cartas na manga:** cada carta da mesa anota uma conta por pessoa (`ContaDaCarta`: pontos e goles); Escudo, Passa a bola, Devolve, Batata quente e Dobra mexem nessa conta. Mão secreta, até 3.
- **Noites prontas:** presets só no app (`noites_prontas.dart`), sem mudança no servidor.
  A Noite das brincadeiras é a noite de jogos: sala sem álcool, cofrinho de 3 e todos os jogos menos
  Eu Nunca e Beba se (decidido pelo proprietário em 2026-10-30).
- **Casais em Jogo saiu do app** em 2026-10-30, a pedido do proprietário (ninguém jogava): sem jogo,
  sem marcar par na sala de espera, sem prêmios de casal; saíram também as cartas que pediam casal
  na mesa (bs-039, bs-040, rr-022, rr-024).
- **Visual das cartas** (`carta_de_baralho.dart`): cada jogo tem cor, estampa desenhada no papel
  (`_PintorDaEstampa`) e ilustração 3D num medalhão sobre a faixa do título. As ilustrações são do
  Fluent Emoji da Microsoft (MIT, `cliente/assets/cartas/`, licença junto); o título usa a Lilita One
  (OFL, `assets/fontes/`). A carta inclina com o mouse e com o giroscópio (`flutter_tilt`), nunca com
  o toque, que fica com a rolagem; ao pousar, balança e uma faixa de luz atravessa. Animação só com
  `AnimationController`/`TweenAnimationBuilder`: o `flutter_animate` deixava timer pendente nos testes.
- **Sala sem álcool** (`ConfiguracaoDoJogo.SemAlcool`, `Sala.SemAlcool.cs`): o cofrinho cheio (ou a
  dose) vira prenda, sorteada por nível de `Dados/prendas.json` e guardada na rodada; no elogio, quem a
  turma escolheu passa uma prenda. `Goles` passa a contar prendas, e o "sem álcool" individual não vale
  (`SoPontos`). Carta que fala de bebida não sai; na regra, "bebeu" vira "leva ponto"
  (`Baralho.SemBebida`). No fim, o 🤡 Mico da noite (`Sala.Mico.cs`): quem tem mais pontos paga, a
  turma vota entre três micos sem ver a parcial, empate decide na sorte. Textos fixos do app com
  "gole" passam por `semAlcoolNoTexto`/`paraASala` (`bebida.dart`).
- **Mural não fica no servidor:** cada um salva as fotos no fim.
- **Comando da sala:** quem está no comando passa para outro (menu ou sala de espera). Celular sem
  consultar a sala por 90 s (`Sala.TempoSemSinal`) perde o comando para o próximo da mesa que está aí;
  a presença é marcada a cada `Reconhecer` (consulta de 6 s ou ação).
- **Reações:** 😂 🔥 💀 😱, uma por pessoa por carta, contagem anônima; a carta com mais reações
  (mínimo 2) vira a Carta da noite no resumo.
- **Celular na mesa:** a tela não apaga dentro da sala (Wake Lock); som e vibração na revelação,
  no vacilo e no fim do tempo (Web Audio, sem arquivo), desligáveis por celular.
- **Voz das cartas:** só o celular de quem comanda lê a carta nova (`speechSynthesis`, sem servidor):
  vários falando juntos viram eco. Personagens em rodízio pelo número da carta (`Personagem` em
  `voz.dart`: tom e velocidade). Mímica, Impostor e Correio só são anunciados, nunca lidos.
  Liga e desliga por celular no menu ⋮ (ligada por padrão).
- **Impostor:** quem é o impostor fica em `Rodada.Impostor` e só sai na revelação (o `Alvo` fica
  nulo); cada celular só sabe de si (`SouImpostor`). Pegaram = impostor sozinho no topo dos votos
  (empate, ele escapa). Escapou: carta na manga para ele, ponto para quem votou errado. Peso 1.
- **Termine a frase:** duas fases na mesma carta (`Rodada.Escrevendo`): a resposta é a frase (até
  40 letras, guardada em `Rodada.Frases`) e, quando todos na mesa escreveram, vira o voto no índice
  de `OrdemDasFrases`. O autor só sai na revelação e só nas mais votadas, que distribuem goles
  (`Elogio`) e ganham carta na manga. Quem comanda passa para a votação com 2 frases. Peso 1
  (com 2, a mímica caía abaixo de 1 em 8).
- **Duas verdades e uma mentira:** a pessoa da vez é o `Alvo` (rodízio). Ela manda as três frases
  e a mentira por `POST /duas-verdades` (`Rodada.Afirmacoes`, `Rodada.Mentira`); a turma vê as
  frases e só ela vê `MinhaMentira`. O voto é o índice pelo `Responder`. Quem errou leva ponto;
  ninguém acertou → ela distribui goles (`Elogio`) e soma `MentirasPerfeitas` (prêmio 🤥
  "Mentiroso(a) de respeito"). Depois da revelação, ela fica com o "🎤 Contei" pendente. Peso 1.
- **Servidor dormindo:** o app cutuca `/api/saude` ao abrir e mostra "Carregando o aplicativo Baralho da Resenha, aguarde…" com um carregando depois de 3 s.
  Durante a noite o próprio servidor se cutuca (`MantemAcordado`): com sala ativa nas últimas 3 h,
  chama `RENDER_EXTERNAL_URL/api/saude` a cada 10 min, porque celular bloqueado não consulta nada.
- **Rodízio do {jogador}:** a carta chama quem foi chamado menos vezes (`Jogador.Chamadas`), a sorte
  só desempata; quem chega no meio entra com o mínimo da mesa. O impostor continua sorteado.
- **Peso por jogo:** cada jogo ligado sai Pouco (metade), Normal ou Muito (dobro)
  (`ConfiguracaoDoJogo.Muito`/`Pouco`); vale também para a chance da regra-relâmpago e da música.

## Revisão das cartas

Página de revisão (artifact do Claude): https://claude.ai/artifact/9ytiuEbKhMgNk2me5es49y
Guarda as decisões do proprietário (manter / cortar / mudar) por id de carta e as cartas novas
que ele escrever. Quando ele avisar que terminou, ler as marcações e aplicar em `cartas.json`.

## Estado

- Testes: servidor (xUnit) e cliente (flutter test) passando.
- Testado com a turma em celulares reais: umas 3 noites até 2026-10-28.
- Revisão das cartas: todas as marcações aplicadas até 2026-10-28.

## Banco de ideias

- Esquenta começando no Resenha e velocidade do esquenta (deixados para depois em 2026-10-19).
- Guardar a sala para sobreviver a um deploy no meio da noite (esbarra em "nada vai para disco").
- Voz das cartas com mais graça (pesquisado em 2026-10-28, em ordem de esforço):
  - Uma voz do aparelho diferente para cada personagem (Luciana/Felipe no iPhone, as do Google no
    Android), escolhida pelo nome; sem a voz, fica como hoje.
  - Vinheta gravada: alguém da mesa grava "Duelo!", "Atenção, turma!"… e o app toca antes da carta,
    com efeito de esquilo ou voz grossa pela velocidade do áudio. Só em memória, como as selfies.
  - Voz neural no navegador (Piper ou Kokoro, que tem Dora, Alex e Santa em pt-BR): sem servidor,
    mas baixa dezenas de MB e pode ser lenta no celular. Testar num protótipo antes.
  - Clonar a voz de alguém da mesa: só com serviço pago (ElevenLabs) ou modelo aberto em GPU própria.
    Esbarra em "nada sai da sala" e no custo; não há nada pronto para Flutter.
- Jogos novos para depois (escolhidos pelo proprietário em 2026-10-30, junto com o Chuta aí e a
  Batata quente, que já entraram):
  - 📡 Na Mesma Onda (estilo Wavelength): a pessoa da vez vê um alvo escondido numa régua
    ("comida ruim ↔ comida boa"), dá uma pista em voz alta e a turma arrasta um ponteiro; quanto
    mais perto do alvo, menos gente bebe. Esforço médio.
  - 🛑 Stop / Adedonha: sai uma letra e umas categorias, cada um escreve no celular, o primeiro
    aperta STOP para todos; na revelação a turma derruba resposta forçada no voto e resposta
    repetida não vale. Esforço médio (o grosso é a votação para derrubar).
  - ⚡ Reflexo (2026-10-30, ficou para depois quando entraram Quem sou eu, Isso ou aquilo, Palavra
    proibida e Quem escreveu): todos os celulares mostram "Espera…" e ficam verdes ao mesmo tempo num
    instante sorteado; quem toca por último (ou antes do verde) leva ponto. Cuidado técnico: medir o
    tempo em cada celular, a partir de um horário marcado pelo servidor, para a internet não decidir.
