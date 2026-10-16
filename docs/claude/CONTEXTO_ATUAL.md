# Baralho da Resenha — Contexto atual

> Atualizado em: 2026-10-16

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
2 times de 6 a 8, 3 times com 9+).

## Regras de produto já decididas

- **Cofrinho de goles:** cada vez que a carta pega alguém vale 1 ponto; o gole só sai quando o
  cofrinho enche (Devagar 3, Normal 2, Raiz 1). Padrão: Devagar.
- **Níveis:** 85% das cartas são do nível escolhido; o que vem de baixo são só as cartas `destaque`.
- **Leve não é infantil:** humor de adulto sem malícia.
- **Votação nunca é Beba se:** vira votação no celular, duelo ou tribunal.
- **Dose de verdade:** carta com `goles` ("bebe 2") é gole direto, fora do cofrinho (`Punir`/`Perdoar`).
- **Cronômetro sincronizado:** o servidor guarda o fim; cada celular conta a partir do que falta.
- **Noites prontas:** presets só no app (`noites_prontas.dart`), sem mudança no servidor.
- **Mural não fica no servidor:** cada um salva as fotos no fim.

## Revisão das cartas

Página de revisão (artifact do Claude): https://claude.ai/artifact/9ytiuEbKhMgNk2me5es49y
Guarda as decisões do proprietário (manter / cortar / mudar) por id de carta e as cartas novas
que ele escrever. Quando ele avisar que terminou, ler as marcações e aplicar em `cartas.json`.

## Estado

- Testes: servidor (xUnit) e cliente (flutter test) passando.
- Ainda não testado com a turma em celulares reais (só Chrome com tela de celular).
- Ideias em aberto: Esquenta começando no Resenha, peso por jogo,
  velocidade do esquenta, cartas da turma permanentes (exigiriam banco).
