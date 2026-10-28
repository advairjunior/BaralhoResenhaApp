using BaralhoResenhaApp.Api.Dominio;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Quem caiu da sala (celular trocou de navegador, apagou a aba) entra de novo
/// com o mesmo nome e volta a ser a mesma pessoa, sem virar "Fabricio 2".
/// </summary>
public sealed class VoltarParaASalaTestes
{
    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Fabricio, FakeTimeProvider Relogio);

    private static Mesa NovaMesa()
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([
            new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1"),
        ]), new Random(1), relogio);
        var ana = sala.Entrar("Ana", false);
        var fabricio = sala.Entrar("Fabricio", false);
        return new Mesa(sala, ana, fabricio, relogio);
    }

    [Fact]
    public void QuemSumiuVoltaComOMesmoNomeEContinuaSendoAMesmaPessoa()
    {
        var mesa = NovaMesa();
        mesa.Fabricio.Pontos = 4;
        var tokenAntigo = mesa.Fabricio.Token;

        mesa.Relogio.Advance(Sala.TempoParaVoltar);
        var voltou = mesa.Sala.Entrar(" fabricio ", false);

        Assert.Equal(mesa.Fabricio.Id, voltou.Id);
        Assert.Equal(4, voltou.Pontos);
        Assert.NotEqual(tokenAntigo, voltou.Token);
        Assert.Equal(2, mesa.Sala.Jogadores.Count);
        Assert.Equal(mesa.Fabricio.Id, mesa.Sala.Visao(voltou.Token).EuId);
    }

    [Fact]
    public void OCelularAntigoDeixaDeValerQuandoAPessoaVolta()
    {
        var mesa = NovaMesa();
        var tokenAntigo = mesa.Fabricio.Token;

        mesa.Relogio.Advance(Sala.TempoParaVoltar);
        mesa.Sala.Entrar("Fabricio", false);

        Assert.Throws<JogadorNaoReconhecidoException>(() => mesa.Sala.Visao(tokenAntigo));
    }

    [Fact]
    public void QuemCriouASalaVoltaContinuandoNoComando()
    {
        var mesa = NovaMesa();

        mesa.Relogio.Advance(Sala.TempoParaVoltar);
        var voltou = mesa.Sala.Entrar("Ana", false);

        Assert.True(voltou.Anfitriao);
        Assert.Single(mesa.Sala.Jogadores, j => j.Anfitriao);
    }

    [Fact]
    public void NomeDeQuemEstaJogandoAgoraContinuaRecusado()
    {
        var mesa = NovaMesa();

        mesa.Relogio.Advance(Sala.TempoParaVoltar - TimeSpan.FromSeconds(1));
        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Entrar("Fabricio", false));

        Assert.Equal(Sala.MensagemDeNomeEmUso, erro.Message);
    }

    [Fact]
    public void CadaConsultaDoCelularMostraQueAPessoaContinuaNaSala()
    {
        var mesa = NovaMesa();

        mesa.Relogio.Advance(Sala.TempoParaVoltar - TimeSpan.FromSeconds(5));
        mesa.Sala.Visao(mesa.Fabricio.Token);
        mesa.Relogio.Advance(TimeSpan.FromSeconds(10));

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Entrar("Fabricio", false));
    }

    [Fact]
    public void AcentoNaoCriaOutraPessoa()
    {
        var mesa = NovaMesa();

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Entrar("Fabrício", false));

        mesa.Relogio.Advance(Sala.TempoParaVoltar);
        Assert.Equal(mesa.Fabricio.Id, mesa.Sala.Entrar("Fabrício", false).Id);
    }
}
