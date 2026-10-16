# Como continuar o Baralho da Resenha em uma nova conversa

## Prompt de abertura

Cole isso no primeiro chat ao abrir o projeto no Claude Code:

```
Projeto BaralhoResenhaApp — jogo de festa Flutter Web/PWA + ASP.NET Core, salas em memória, Render.
Leia CLAUDE.md, docs/claude/CONTEXTO_ATUAL.md e git log --oneline -10.
Faça uma auditoria somente leitura e me conte o estado atual antes de qualquer alteração.
```

## Checklist de validação do contexto

- [ ] O Claude sabe que as salas ficam em memória, sem banco?
- [ ] O Claude sabe que só quem criou a sala mexe nas cartas, também no servidor?
- [ ] O Claude sabe do cofrinho de goles e que Leve não pode ser infantil?
- [ ] O Claude sabe que as cartas são para amigos, nada centrado em casal?
- [ ] O Claude sabe que `main` faz deploy automático no Render?
- [ ] O Claude sabe que push requer autorização explícita?

Se algum item falhar, peça: `Releia docs/claude/CONTEXTO_ATUAL.md e CLAUDE.md`.

## Verificação rápida do estado do projeto

```powershell
git status
git log --oneline -10
dotnet test BaralhoResenhaApp.sln
cd cliente; dart analyze; flutter test
```

## Rodar localmente

```powershell
.\rodar.ps1
```

Abre em `http://localhost:5090`. Para testar com o celular na mesma rede Wi-Fi, use o IP do
computador no lugar de `localhost`.
