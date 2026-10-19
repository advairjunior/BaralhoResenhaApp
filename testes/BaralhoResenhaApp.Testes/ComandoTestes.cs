using BaralhoResenhaApp.Api.Dominio;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// O comando da sala (puxar, pular, revelar) é de uma pessoa só. Quem está
/// com ele pode passar para outro, e se o celular dela sumir (bateria, aba
/// fechada) o comando passa sozinho para quem ainda está na mesa.
/// </summary>
public sealed class ComandoTestes
{
    private static readonly Carta EuNunca = new("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca dormi no cinema.");

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Beto, Jogador Caio, FakeTimeProvider Relogio);

    private static Mesa Montar()
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([EuNunca]), new Random(1), relogio);
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);
        return new Mesa(sala, ana, beto, caio, relogio);
    }

    [Fact]
    public void QuemEstaNoComandoPassaParaOutro()
    {
        var mesa = Montar();

        mesa.Sala.PassarComando(mesa.Ana.Token, mesa.Caio.Id);

        Assert.False(mesa.Ana.Anfitriao);
        Assert.True(mesa.Caio.Anfitriao);
        Assert.True(mesa.Sala.Visao(mesa.Caio.Token).SouAnfitriao);
    }

    [Fact]
    public void SoQuemEstaNoComandoPassaOComando()
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.PassarComando(mesa.Beto.Token, mesa.Beto.Id));

        Assert.Equal("Só quem está no comando pode passar o comando.", erro.Message);
        Assert.True(mesa.Ana.Anfitriao);
    }

    [Fact]
    public void ComandoSoVaiParaQuemEstaNaSala()
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.PassarComando(mesa.Ana.Token, Guid.NewGuid()));

        Assert.Equal("Essa pessoa não está na sala.", erro.Message);
        Assert.True(mesa.Ana.Anfitriao);
    }

    [Fact]
    public void CelularDeQuemEstaNoComandoSumiuOComandoPassaParaOProximoDaLista()
    {
        var mesa = Montar();
        // Beto e Caio seguem consultando a sala; a Ana some.
        mesa.Relogio.Advance(Sala.TempoSemSinal - TimeSpan.FromSeconds(10));
        mesa.Sala.MarcarPresenca(mesa.Caio.Token);
        mesa.Relogio.Advance(TimeSpan.FromSeconds(5));
        mesa.Sala.MarcarPresenca(mesa.Beto.Token);
        Assert.True(mesa.Ana.Anfitriao);

        mesa.Relogio.Advance(TimeSpan.FromSeconds(6));
        var trocou = mesa.Sala.MarcarPresenca(mesa.Caio.Token);

        Assert.True(trocou);
        Assert.False(mesa.Ana.Anfitriao);
        Assert.True(mesa.Beto.Anfitriao);
        Assert.False(mesa.Caio.Anfitriao);
    }

    [Fact]
    public void ComandoNaoPassaParaQuemTambemSumiu()
    {
        var mesa = Montar();
        mesa.Relogio.Advance(Sala.TempoSemSinal + TimeSpan.FromSeconds(1));

        // O Beto também sumiu: o comando pula para o Caio, que está aí.
        Assert.True(mesa.Sala.MarcarPresenca(mesa.Caio.Token));

        Assert.True(mesa.Caio.Anfitriao);
        Assert.False(mesa.Beto.Anfitriao);
    }

    [Fact]
    public void QuemEstaNoComandoEConsultandoASalaNaoPerdeOComando()
    {
        var mesa = Montar();
        for (var vez = 0; vez < 30; vez++)
        {
            mesa.Relogio.Advance(TimeSpan.FromSeconds(6));
            mesa.Sala.MarcarPresenca(mesa.Ana.Token);
            Assert.False(mesa.Sala.MarcarPresenca(mesa.Beto.Token));
        }

        Assert.True(mesa.Ana.Anfitriao);
    }

    [Fact]
    public void QualquerAcaoDeQuemEstaNoComandoContaComoPresenca()
    {
        var mesa = Montar();
        mesa.Relogio.Advance(Sala.TempoSemSinal - TimeSpan.FromSeconds(1));
        mesa.Sala.Configurar(mesa.Ana.Token,
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], ZonaSegura: true));

        mesa.Relogio.Advance(TimeSpan.FromSeconds(2));

        Assert.False(mesa.Sala.MarcarPresenca(mesa.Beto.Token));
        Assert.True(mesa.Ana.Anfitriao);
    }
}
