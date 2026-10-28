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
Casais em Jogo (opcional, desligado por padrão) · Tribunal da Turma · Rodada de Elogios ·
Correio da Resenha (bilhetes anônimos de até 20 letras) · Imagem e Ação (1 mímico até 5 pessoas,
2 times de 6 a 8, 3 times com 9+) · Jurados · Roda de Música · Impostor (palavra para todos menos
um, que só sabe o tema; pistas em voz alta na ordem do app; voto secreto; 4+ pessoas) ·
Termine a frase (cada um completa o começo da carta em segredo, a turma vota sem saber de quem é; 3+ pessoas) ·
Duas verdades e uma mentira (a pessoa da vez escreve três frases sobre si e a turma vota na mentira; 3+ pessoas).

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
- **Mural não fica no servidor:** cada um salva as fotos no fim.
- **Comando da sala:** quem está no comando passa para outro (menu ou sala de espera). Celular sem
  consultar a sala por 90 s (`Sala.TempoSemSinal`) perde o comando para o próximo da mesa que está aí;
  a presença é marcada a cada `Reconhecer` (consulta de 6 s ou ação).
- **Reações:** 😂 🔥 💀 😱, uma por pessoa por carta, contagem anônima; a carta com mais reações
  (mínimo 2) vira a Carta da noite no resumo.
- **Celular na mesa:** a tela não apaga dentro da sala (Wake Lock); som e vibração na revelação,
  no vacilo e no fim do tempo (Web Audio, sem arquivo), desligáveis por celular.
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
