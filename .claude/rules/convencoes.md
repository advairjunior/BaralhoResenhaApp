# Convenções de código

## Idioma

- Todo código, comentários, commits, nomes de classes, métodos e variáveis em português do Brasil.
- Exceções: palavras reservadas da linguagem, nomes de frameworks e bibliotecas externas.

## Servidor (.NET / ASP.NET Core)

- Minimal APIs no `Program.cs` — sem controllers. Toda ação devolve a visão da sala
  e publica no tempo real (`/api/tempo-real/{codigo}`).
- A sala é dividida em arquivos parciais por assunto: `Sala.cs` (rodadas e revelação),
  `Sala.Casais.cs`, `Sala.Correio.cs`, `Sala.Duelo.cs`, `Sala.ImagemEAcao.cs`,
  `Sala.Regras.cs`, `Sala.Bebida.cs`, `Sala.Momentos.cs`, `Sala.Tirar.cs`, `Sala.Fim.cs`.
- Todo acesso à sala passa pelo trinco dela (`lock (_trinco)`): vários celulares agem ao mesmo tempo.
- Erros de regra do jogo são `AcaoNaoPermitidaException`; a mensagem vai direto para a tela.
- Quem é pego pela carta ganha ponto com `Pegar` (cofrinho de goles), nunca mexendo em `Goles` direto.

## Cartas

- Cartas em `servidor/BaralhoResenhaApp.Api/Dados/cartas.json`, uma por linha; iscas das
  regras-relâmpago em `Dados/iscas.json`. Os dois são recursos embutidos na DLL.
- Ids estáveis por jogo (`en-`, `mp-`, `bs-`, `rr-`, `cs-`, `tr-`, `el-`, `co-`, `ia-`, `ju-`, `mu-`, `im-`):
  a página de revisão usa o id para guardar as decisões.
- Cartas são para a turma como amigos: nada centrado em casal, Leve é humor de adulto sem
  malícia (nunca infantil), e o que pede votação nunca fica no Beba se.

## Cliente (Flutter)

- `telas/sala.dart` controla a sala (SSE + consulta a cada 6 s como reserva) e implementa `AcoesDaSala`.
- As outras telas só desenham a `VisaoDaSala` e chamam as ações.
- Comunicação com a API em `infraestrutura/api_baralho.dart`.

## Testes

- Servidor: xUnit em `testes/BaralhoResenhaApp.Testes`, regras testadas direto na `Sala`
  com `Random` de semente fixa; rotas em `SalasApiTestes`.
- Cliente: testes de tela com `ServidorFalso` (`test/apoio.dart`), sem rede.
- Filtro para rodar testes específicos: `--filter FullyQualifiedName~NomeDaClasseTestes`.

## Estrutura de pastas

```
servidor/BaralhoResenhaApp.Api/    → API .NET (e o site Flutter publicado em wwwroot)
cliente/                           → Flutter Web/PWA
testes/BaralhoResenhaApp.Testes/   → testes xUnit
docs/                              → documentação
```
