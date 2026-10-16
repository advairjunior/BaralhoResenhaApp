using System.Text.Json.Serialization;
using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(CatalogoDeCartas.Carregar());
builder.Services.AddSingleton<SalasEmMemoria>();
builder.Services.AddSingleton<NotificadorTempoReal>();
builder.Services.ConfigureHttpJsonOptions(opcoes =>
    opcoes.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddCors(opcoes => opcoes.AddDefaultPolicy(politica => politica
    .AllowAnyOrigin()
    .AllowAnyHeader()
    .AllowAnyMethod()));

var app = builder.Build();

app.UseMiddleware<BaralhoResenhaApp.Api.TratamentoDeErros>();
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/api/saude", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/tempo-real/{codigo}", async Task (
    string codigo,
    HttpResponse resposta,
    NotificadorTempoReal notificador,
    CancellationToken cancelamento) =>
{
    resposta.ContentType = "text/event-stream";
    resposta.Headers.CacheControl = "no-cache";
    resposta.Headers.Append("X-Accel-Buffering", "no");
    await foreach (var evento in notificador.Assinar(codigo, cancelamento))
    {
        var mensagem = evento == "pulso" ? ": pulso\n\n" : $"data: {evento}\n\n";
        await resposta.WriteAsync(mensagem, cancelamento);
        await resposta.Body.FlushAsync(cancelamento);
    }
});

app.MapPost("/api/salas", (EntrarNaSala requisicao, SalasEmMemoria salas) =>
{
    var sala = salas.Criar();
    try
    {
        var jogador = sala.Entrar(requisicao.Nome, requisicao.SemAlcool);
        return Results.Created($"/api/salas/{sala.Codigo}", new EntradaNaSala(sala.Codigo, jogador.Token));
    }
    catch
    {
        salas.DescartarSeVazia(sala);
        throw;
    }
});

app.MapPost("/api/salas/{codigo}/jogadores", (
    string codigo, EntrarNaSala requisicao, SalasEmMemoria salas, NotificadorTempoReal notificador) =>
{
    var sala = salas.Obter(codigo);
    var jogador = sala.Entrar(requisicao.Nome, requisicao.SemAlcool);
    notificador.Publicar(sala.Codigo);
    return Results.Ok(new EntradaNaSala(sala.Codigo, jogador.Token));
});

app.MapGet("/api/salas/{codigo}", (string codigo, HttpRequest http, SalasEmMemoria salas) =>
    Results.Ok(salas.Obter(codigo).Visao(Token(http))));

app.MapDelete("/api/salas/{codigo}/jogadores/eu", (
    string codigo, HttpRequest http, SalasEmMemoria salas, NotificadorTempoReal notificador) =>
{
    var sala = salas.Obter(codigo);
    sala.Sair(Token(http));
    salas.DescartarSeVazia(sala);
    notificador.Publicar(sala.Codigo);
    return Results.NoContent();
});

// Selfie do perfil do jogador.
app.MapPut("/api/salas/{codigo}/jogadores/eu/foto", async Task<IResult> (
    string codigo, HttpRequest http, SalasEmMemoria salas,
    NotificadorTempoReal notificador, CancellationToken cancelamento) =>
{
    var sala = salas.Obter(codigo);
    var token = Token(http);
    sala.Reconhecer(token);
    sala.DefinirFoto(token, await LerImagem(http, cancelamento));
    notificador.Publicar(sala.Codigo);
    return Results.Ok(sala.Visao(token));
});

// Selfie de reação para o mural da noite, tirada na revelação.
app.MapPut("/api/salas/{codigo}/momentos", async Task<IResult> (
    string codigo, int rodada, HttpRequest http, SalasEmMemoria salas,
    NotificadorTempoReal notificador, CancellationToken cancelamento) =>
{
    var sala = salas.Obter(codigo);
    var token = Token(http);
    sala.Reconhecer(token);
    sala.RegistrarMomento(token, rodada, await LerImagem(http, cancelamento));
    notificador.Publicar(sala.Codigo);
    return Results.Ok(sala.Visao(token));
});

app.MapPut("/api/salas/{codigo}/jogadores/eu/par", (
    string codigo, DefinirPar requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.DefinirPar(token, requisicao.ParId)));

app.MapPost("/api/salas/{codigo}/julgar", (
    string codigo, JulgarPalpite requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.Julgar(token, requisicao.Rodada, requisicao.Acertou)));

app.MapPost("/api/salas/{codigo}/apontado", (
    string codigo, MarcarApontado requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.MarcarApontado(token, requisicao.Rodada, requisicao.JogadorId)));

app.MapPost("/api/salas/{codigo}/favorito", (
    string codigo, EscolherFavorito requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.EscolherFavorito(token, requisicao.Rodada, requisicao.Indice)));

app.MapPost("/api/salas/{codigo}/vacilo", (
    string codigo, MarcarApontado requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.MarcarVacilo(token, requisicao.Rodada, requisicao.JogadorId)));

app.MapPost("/api/salas/{codigo}/mimica", (
    string codigo, ResultadoDaMimica requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.ResultadoDaMimica(token, requisicao.Rodada, requisicao.Vencedor)));

app.MapPost("/api/salas/{codigo}/tirar", (
    string codigo, AcaoNaRodada requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Tirar(token, requisicao.Rodada)));

app.MapPost("/api/salas/{codigo}/encerrar", (
    string codigo, HttpRequest http, SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Encerrar(token)));

app.MapPost("/api/salas/{codigo}/retomar", (
    string codigo, HttpRequest http, SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Retomar(token)));

app.MapGet("/api/salas/{codigo}/fotos/{fotoId}", (
    string codigo, string fotoId, HttpResponse resposta, SalasEmMemoria salas) =>
{
    var foto = salas.Obter(codigo).Foto(fotoId);
    if (foto is null) return Results.NotFound();
    // Cada foto nova ganha outro id: dá para guardar no navegador à vontade.
    resposta.Headers.CacheControl = "public, max-age=86400, immutable";
    return Results.Bytes(foto.Conteudo, foto.TipoDeConteudo);
});

app.MapPut("/api/salas/{codigo}/configuracao", (
    string codigo, ConfiguracaoDoJogo configuracao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Configurar(token, configuracao)));

app.MapPost("/api/salas/{codigo}/comecar", (
    string codigo, HttpRequest http, SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Comecar(token)));

app.MapPost("/api/salas/{codigo}/respostas", (
    string codigo, ResponderCarta requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador,
        (sala, token) => sala.Responder(token, requisicao.Rodada, requisicao.Resposta)));

app.MapPost("/api/salas/{codigo}/revelar", (
    string codigo, AcaoNaRodada requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Revelar(token, requisicao.Rodada)));

app.MapPost("/api/salas/{codigo}/proxima", (
    string codigo, AcaoNaRodada requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.Proxima(token, requisicao.Rodada)));

app.MapPost("/api/salas/{codigo}/bebi", (
    string codigo, AcaoNaRodada requisicao, HttpRequest http,
    SalasEmMemoria salas, NotificadorTempoReal notificador) =>
    Agir(codigo, http, salas, notificador, (sala, token) => sala.AlternarBebi(token, requisicao.Rodada)));

app.MapFallbackToFile("index.html");

app.Run();

// Toda ação devolve a sala já atualizada para quem tocou no botão;
// os outros celulares ficam sabendo pelo tempo real.
static IResult Agir(
    string codigo, HttpRequest http, SalasEmMemoria salas,
    NotificadorTempoReal notificador, Action<Sala, string> acao)
{
    var sala = salas.Obter(codigo);
    var token = Token(http);
    acao(sala, token);
    notificador.Publicar(sala.Codigo);
    return Results.Ok(sala.Visao(token));
}

// As fotos chegam cruas no corpo (image/jpeg), sem formulário.
static async Task<byte[]> LerImagem(HttpRequest http, CancellationToken cancelamento)
{
    using var memoria = new MemoryStream();
    var buffer = new byte[16 * 1024];
    int lidos;
    while ((lidos = await http.Body.ReadAsync(buffer, cancelamento)) > 0)
    {
        memoria.Write(buffer, 0, lidos);
        if (memoria.Length > FotoDoJogador.TamanhoMaximo)
            throw new AcaoNaoPermitidaException("A foto ficou grande demais. Tente de novo.");
    }
    return memoria.ToArray();
}

static string Token(HttpRequest http)
{
    var cabecalho = http.Headers.Authorization.ToString();
    return cabecalho.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
        ? cabecalho["Bearer ".Length..].Trim()
        : string.Empty;
}

public sealed record EntrarNaSala(string Nome, bool SemAlcool = false);
public sealed record EntradaNaSala(string Codigo, string Token);
public sealed record ResponderCarta(int Rodada, string Resposta);
public sealed record AcaoNaRodada(int Rodada);
public sealed record DefinirPar(Guid? ParId);
public sealed record JulgarPalpite(int Rodada, bool Acertou);
public sealed record MarcarApontado(int Rodada, Guid JogadorId);
public sealed record EscolherFavorito(int Rodada, int Indice);
public sealed record ResultadoDaMimica(int Rodada, int? Vencedor);

public partial class Program;
