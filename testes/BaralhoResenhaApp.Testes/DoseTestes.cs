using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Duas formas de pagar a carta: a comum soma ponto no cofrinho; a que diz
/// "bebe 2" é gole de verdade, fora do cofrinho.
/// </summary>
public sealed class DoseTestes
{
    private static (Sala Sala, Jogador Ana, Jogador Bia) Mesa(bool biaSemAlcool = false)
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("bs-2", ModoDeJogo.BebaSe, NivelDaCarta.Resenha, "{jogador} conta o maior mico ou bebe 2.", Goles: 2),
        ]), new Random(1));
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", biaSemAlcool);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Resenha, [ModoDeJogo.BebaSe], true));
        sala.Comecar(ana.Token);
        return (sala, ana, bia);
    }

    [Fact]
    public void CartaQueMandaBeber2EhGoleDeVerdadeForaDoCofrinho()
    {
        var (sala, ana, _) = Mesa();

        sala.AlternarBebi(ana.Token, sala.Rodada!.Numero);

        Assert.Equal(2, ana.Goles);
        Assert.Equal(0, ana.Cofrinho);
        Assert.Equal(2, ana.Pontos);
        Assert.Equal([ana.Id], sala.Rodada.BebemAgora);
        Assert.Equal(2, sala.Visao(ana.Token).Rodada!.Goles);

        sala.AlternarBebi(ana.Token, sala.Rodada.Numero);
        Assert.Equal(0, ana.Goles);
        Assert.Equal(0, ana.Pontos);
        Assert.Empty(sala.Rodada.BebemAgora);
    }

    [Fact]
    public void NaDoseQuemJogaSemAlcoolLevaOsPontos()
    {
        var (sala, _, bia) = Mesa(biaSemAlcool: true);

        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        Assert.Equal(2, bia.Pontos);
        Assert.Equal(0, bia.Goles);
    }
}
