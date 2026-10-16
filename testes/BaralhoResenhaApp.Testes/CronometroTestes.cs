using BaralhoResenhaApp.Api.Dominio;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Cronômetro da carta: quem criou a sala dá o "valendo" e todos os
/// celulares contam o mesmo tempo.
/// </summary>
public sealed class CronometroTestes
{
    private static (Sala Sala, Jogador Ana, Jogador Bia, FakeTimeProvider Relogio) Mesa(Carta carta, ModoDeJogo modo)
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(1), relogio);
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", false);
        sala.Entrar("Caio", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [modo], true));
        sala.Comecar(ana.Token);
        return (sala, ana, bia, relogio);
    }

    [Fact]
    public void CartaComSegundosTemCronometroQueSoQuemCriouASalaDispara()
    {
        var (sala, ana, bia, relogio) = Mesa(
            new Carta("el-1", ModoDeJogo.Elogios, NivelDaCarta.Leve, "Cada um diz uma qualidade em 5 segundos."),
            ModoDeJogo.Elogios);
        var rodada = sala.Rodada!.Numero;

        var antes = sala.Visao(bia.Token).Rodada!;
        Assert.Equal(5, antes.CronometroSegundos);
        Assert.Null(antes.CronometroRestanteMs);
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.IniciarCronometro(bia.Token, rodada));

        sala.IniciarCronometro(ana.Token, rodada);
        relogio.Advance(TimeSpan.FromSeconds(2));
        Assert.Equal(3000, sala.Visao(bia.Token).Rodada!.CronometroRestanteMs);

        relogio.Advance(TimeSpan.FromSeconds(10));
        Assert.Equal(0, sala.Visao(bia.Token).Rodada!.CronometroRestanteMs);
    }

    [Fact]
    public void ApontaNo3TemContagemDe3SegundosParaTodos()
    {
        var (sala, ana, bia, _) = Mesa(
            new Carta("mp-1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem ronca mais?"), ModoDeJogo.MaisProvavel);
        sala.ChanceDeVotacao = 0;
        sala.Proxima(ana.Token, sala.Rodada!.Numero);

        Assert.Equal(3, sala.Visao(bia.Token).Rodada!.CronometroSegundos);
        sala.IniciarCronometro(ana.Token, sala.Rodada.Numero);
        Assert.Equal(3000, sala.Visao(bia.Token).Rodada!.CronometroRestanteMs);
    }

    [Fact]
    public void MimicaTemSessentaSegundosECartaSemTempoNaoTemCronometro()
    {
        var (mimica, ana, _, _) = Mesa(
            new Carta("ia-1", ModoDeJogo.ImagemEAcao, NivelDaCarta.Leve, "Fazer baliza", Categoria: "Ação"),
            ModoDeJogo.ImagemEAcao);
        Assert.Equal(60, mimica.Visao(ana.Token).Rodada!.CronometroSegundos);

        var (comum, outra, _, _) = Mesa(
            new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos."), ModoDeJogo.BebaSe);
        Assert.Null(comum.Visao(outra.Token).Rodada!.CronometroSegundos);
        Assert.Throws<AcaoNaoPermitidaException>(() => comum.IniciarCronometro(outra.Token, comum.Rodada!.Numero));
    }
}
