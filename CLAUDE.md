# Baralho da Resenha

Flutter Web/PWA + ASP.NET Core Minimal APIs (.NET 10). Salas em memória, sem banco.
Deploy automático via `main` → Render (Docker). Mesmas convenções do TocaEssaApp.

## Regras essenciais

- **Idioma:** código, comentários, commits e nomes em português do Brasil.
- **Testes:** todo comportamento novo nasce de um teste que falha pelo motivo esperado.
- **Git destrutivo:** `reset --hard`, `push --force`, `branch -D` somente após autorização explícita.
- **Push:** somente após autorização explícita; apresentar commits e resultados de testes antes.
- **Credenciais:** nenhuma chave, senha ou `.env` entra no repositório. O login do GitHub vem do `gh`.
- **`.vs/`, `bin/`, `obj/`:** nunca incluir em commits.

## Regras detalhadas

@.claude/rules/fluxo.md
@.claude/rules/seguranca.md
@.claude/rules/convencoes.md

## Onde fica cada coisa

- Regras do jogo (estado, rodadas, revelação, pontos): `servidor/BaralhoResenhaApp.Api/Dominio/Sala*.cs`
- Sorteio das cartas (nível, destaque, Zona Segura, mistura sem repetir): `Dominio/Baralho.cs`
- Cartas e iscas: `servidor/BaralhoResenhaApp.Api/Dados/cartas.json` e `iscas.json` (recursos embutidos)
- Rotas: `Program.cs`. Toda ação devolve a visão da sala e publica no tempo real (`/api/tempo-real/{codigo}`).
- Cliente: `cliente/lib/telas/sala.dart` controla a sala (SSE + consulta a cada 6 s como reserva);
  as outras telas só desenham.
- O token do jogador fica no aparelho (`shared_preferences`, chave `sala_<CODIGO>`).

## Contexto e continuidade

- Arquitetura e estado atual: `docs/claude/CONTEXTO_ATUAL.md`
- Como abrir uma nova conversa: `docs/claude/COMO_CONTINUAR.md`

## Referências rápidas

- Deploy e smoke test: `docs/DEPLOY_RENDER.md`
- Executar localmente: `.\rodar.ps1`
