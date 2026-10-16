# Fluxo de trabalho

## Antes de qualquer alteração

1. Executar inspeção somente leitura: `git status`, `git log --oneline -10`.
2. Ler os arquivos relevantes para entender o estado atual.
3. Explicar o que foi encontrado antes de propor mudanças grandes.

## Ciclo de desenvolvimento

1. Escrever o teste que falha pelo motivo esperado (RED).
2. Executar o teste e confirmar a falha esperada.
3. Implementar o mínimo para passar (GREEN).
4. Executar os testes completos do servidor e do cliente.
5. Conferir no navegador as telas que mudaram (servidor de teste na porta 5091,
   para não brigar com o `rodar.ps1` na 5090).
6. Fazer commit atômico por task.

## Comandos de verificação (executar na raiz)

```powershell
dotnet build BaralhoResenhaApp.sln
dotnet test BaralhoResenhaApp.sln --no-build
cd cliente; dart analyze; flutter test
```

- `flutter analyze` trava nesta máquina (servidor de análise sai com código 255): use `dart analyze`.
- Com o `rodar.ps1` aberto, a DLL em `bin\Debug` fica travada: compile e teste com
  `--artifacts-path <pasta temporária>`.
- Depois de incluir um plugin novo, rode `flutter clean` antes do `flutter build web`
  (o registro dos plugins web fica desatualizado e dá `MissingPluginException`).

## Guia "Como jogar" e ajuda do app

- Funcionalidade nova que a turma vê entra no guia `/como-jogar` na mesma entrega, na medida da
  importância (tabela em `docs/GUIA_COMO_JOGAR.md`): jogo ou mecânica nova ganha seção e captura;
  regra que muda o jeito de jogar atualiza o texto; opção nova vira uma linha; ajuste pequeno só
  refaz a captura afetada; correção interna não mexe no guia.
- Junto: o "ⓘ Como joga" (`cliente/lib/telas/ajuda.dart`) e, para carta na manga, a ficha.
- O jogo tem que se explicar sozinho: ninguém precisa ensinar ninguém na mesa.

## Commits

- Mensagem em português, imperativo: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`.
- Adicionar somente os arquivos da task — nunca `git add .`.
- Nunca commitar `.vs/`, `bin/`, `obj/`, `build/`, `.dart_tool/`.

## Push e deploy

- Apresentar commits e resultados de testes antes do push.
- Push somente após autorização explícita do proprietário.
- Cada push na `main` dispara o deploy no Render; depois do push, seguir o smoke test
  de `docs/DEPLOY_RENDER.md`.
