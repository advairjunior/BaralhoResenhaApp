# Segurança

## Credenciais e dados sensíveis

- Nenhuma chave de API, senha, token ou string de conexão entra em nenhum arquivo versionado.
- Arquivos `.env` e `appsettings.Production.json` com credenciais reais nunca são commitados.
- O login do GitHub não fica no projeto: o git usa o `gh` como `credential.helper`
  (configuração local do repositório, a mesma do TocaEssaApp).
- Antes de qualquer commit, conferir `git status` e `git diff --cached --stat` atrás de arquivos suspeitos.

## Dados da noite

- Salas, selfies e fotos do mural ficam só em memória e somem quando a sala é descartada.
  Nada disso vai para disco, banco ou log.
- O mural não é guardado no servidor: cada um salva as fotos no próprio celular no fim do jogo.
- Foto só é servida para quem tem o código da sala, por id aleatório.

## Regras do jogo que protegem a turma

- O token do jogador é a única identidade: ações nunca aceitam o id de outro jogador como "quem sou eu".
- Só quem criou a sala puxa, pula, revela e tira cartas — também no servidor, não só na tela.
- Respostas secretas (Eu Nunca, votações, Tribunal) só aparecem depois da revelação.
- Correio da Resenha é anônimo de verdade: os bilhetes saem embaralhados e sem autor,
  nem quem criou a sala sabe quem escreveu.
- Imagem e Ação: a palavra só é enviada ao celular de quem faz a mímica.

## Operações Git

- Nunca executar `git reset --hard`, `git push --force`, `git branch -D` sem autorização explícita.
- Nunca usar `--no-verify` para contornar hooks.
- Em caso de conflito, investigar e resolver — nunca descartar alterações do proprietário.
