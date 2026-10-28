using System.Net;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Time.Testing;
using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

public sealed class MantemAcordadoTestes
{
    private sealed class CarteiroFalso : HttpMessageHandler
    {
        public List<Uri> Enderecos { get; } = [];

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage requisicao, CancellationToken cancelamento)
        {
            Enderecos.Add(requisicao.RequestUri!);
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK));
        }
    }

    private static (MantemAcordado, SalasEmMemoria, FakeTimeProvider, CarteiroFalso) Montar(
        string? endereco = "https://baralho-resenha.onrender.com")
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var salas = new SalasEmMemoria(new Baralho([]), relogio);
        var carteiro = new CarteiroFalso();
        var mantem = new MantemAcordado(
            salas, new HttpClient(carteiro), endereco, relogio, NullLogger<MantemAcordado>.Instance);
        return (mantem, salas, relogio, carteiro);
    }

    [Fact]
    public async Task ComSalaEmJogoCutucaASaudePeloEnderecoPublico()
    {
        var (mantem, salas, _, carteiro) = Montar();
        salas.Criar().Entrar("Ana", false);

        Assert.True(await mantem.CutucarSePreciso(CancellationToken.None));

        Assert.Equal("https://baralho-resenha.onrender.com/api/saude", Assert.Single(carteiro.Enderecos).ToString());
    }

    [Fact]
    public async Task SemSalaDeixaOServidorDormir()
    {
        var (mantem, _, _, carteiro) = Montar();

        Assert.False(await mantem.CutucarSePreciso(CancellationToken.None));
        Assert.Empty(carteiro.Enderecos);
    }

    [Fact]
    public async Task SalaParadaHaMaisDeTresHorasDeixaOServidorDormir()
    {
        var (mantem, salas, relogio, carteiro) = Montar();
        salas.Criar().Entrar("Ana", false);

        relogio.Advance(SalasEmMemoria.TempoAcordado + TimeSpan.FromMinutes(1));

        Assert.False(await mantem.CutucarSePreciso(CancellationToken.None));
        Assert.Empty(carteiro.Enderecos);
    }

    [Fact]
    public async Task PausaDaPizzaDeUmaHoraContinuaCutucando()
    {
        var (mantem, salas, relogio, carteiro) = Montar();
        salas.Criar().Entrar("Ana", false);

        relogio.Advance(TimeSpan.FromHours(1));

        Assert.True(await mantem.CutucarSePreciso(CancellationToken.None));
        Assert.Single(carteiro.Enderecos);
    }

    [Fact]
    public async Task RodandoLocalSemEnderecoPublicoNaoCutuca()
    {
        var (mantem, salas, _, carteiro) = Montar(endereco: null);
        salas.Criar().Entrar("Ana", false);

        Assert.False(await mantem.CutucarSePreciso(CancellationToken.None));
        Assert.Empty(carteiro.Enderecos);
    }
}
