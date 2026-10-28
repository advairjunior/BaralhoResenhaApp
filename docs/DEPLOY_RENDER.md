# Deploy no Render

O `render.yaml` cria o serviço `baralho-resenha` (Docker, plano free) e mantém o deploy automático
ligado à branch `main`. O `Dockerfile` compila o Flutter Web e publica junto com a API, então um
único serviço serve o site e a API.

## Antes de enviar para a `main`

Execute na raiz:

```powershell
dotnet build BaralhoResenhaApp.sln
dotnet test BaralhoResenhaApp.sln --no-build
cd cliente
dart analyze
flutter test
```

## Primeiro deploy (uma vez só)

1. No Render, **New → Blueprint** e escolha o repositório `advairjunior/BaralhoResenhaApp`.
2. O Render lê o `render.yaml` e propõe o serviço `baralho-resenha`. Confirme.
3. O primeiro build demora (baixa as imagens do Flutter e do .NET). A saúde é checada em `/api/saude`.

Não há banco nem disco: nada a configurar além disso.

## Plano free: o que esperar

- O serviço dorme depois de um tempo sem acesso; o primeiro acesso da noite demora uns
  segundos para acordar. Abra o site alguns minutos antes de a turma chegar.
- Durante a noite ele não dorme: enquanto houver sala com atividade nas últimas 3 h, o próprio
  servidor chama `RENDER_EXTERNAL_URL/api/saude` a cada 10 min (`MantemAcordado`), mesmo com
  todos os celulares bloqueados. Sem sala em jogo, ele para de se cutucar e dorme normalmente.
  O Render preenche `RENDER_EXTERNAL_URL` sozinho; não há nada a configurar.
- Como as salas ficam em memória, **um deploy ou reinício no meio do jogo derruba a sala**.
  Não faça push durante uma noite de jogo.

## Smoke test depois do deploy

1. Abra `https://<serviço>.onrender.com/api/saude`: deve responder `{"status":"ok"}`.
2. Crie uma sala no celular e entre com um segundo celular pelo QR.
3. Tire uma selfie e confira que ela aparece no outro celular.
4. Comece o jogo e passe algumas cartas: só quem criou a sala consegue puxar a próxima.
5. Responda uma carta de Eu Nunca nos dois celulares e confira a revelação.
6. Encerre a noite e confira os prêmios e o mural.
