using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Cofrinho de goles: cada vez que a carta pega alguém vale um ponto, e o
/// gole só sai quando o cofrinho enche. Senão a turma fica bêbada em meia hora.
/// </summary>
public sealed class BebidaTestes
{
    private static (Sala Sala, Jogador Ana, Jogador Bia) Mesa(RitmoDaBebida ritmo, bool biaSemAlcool = false)
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos."),
        ]), new Random(1));
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", biaSemAlcool);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], true, Ritmo: ritmo));
        sala.Comecar(ana.Token);
        return (sala, ana, bia);
    }

    private static void Pegou(Sala sala, Jogador anfitriao, Jogador quem, int cartas)
    {
        for (var i = 0; i < cartas; i++)
        {
            sala.AlternarBebi(quem.Token, sala.Rodada!.Numero);
            if (i < cartas - 1) sala.Proxima(anfitriao.Token, sala.Rodada.Numero);
        }
    }

    [Fact]
    public void ARegraPadraoEhDevagar()
    {
        Assert.Equal(RitmoDaBebida.Devagar, ConfiguracaoDoJogo.Padrao.Ritmo);
        Assert.Equal(7, ConfiguracaoDoJogo.Padrao.PontosPorGole);
    }

    [Fact]
    public void NoDevagarSoBebeQuandoJuntaSetePontos()
    {
        var (sala, ana, _) = Mesa(RitmoDaBebida.Devagar);

        Pegou(sala, ana, ana, 6);
        Assert.Equal(6, ana.Pontos);
        Assert.Equal(0, ana.Goles);
        Assert.Equal(6, ana.Cofrinho);
        Assert.Empty(sala.Rodada!.BebemAgora);

        sala.Proxima(ana.Token, sala.Rodada.Numero);
        Pegou(sala, ana, ana, 1);
        Assert.Equal(7, ana.Pontos);
        Assert.Equal(1, ana.Goles);
        Assert.Equal(0, ana.Cofrinho);
        Assert.Equal([ana.Id], sala.Visao(ana.Token).Rodada!.BebemAgora);
    }

    [Fact]
    public void NoNormalBebeACadaDoisENoRaizACadaUm()
    {
        var (normal, ana, _) = Mesa(RitmoDaBebida.Normal);
        Pegou(normal, ana, ana, 4);
        Assert.Equal(2, ana.Goles);

        var (raiz, outra, _) = Mesa(RitmoDaBebida.Raiz);
        Pegou(raiz, outra, outra, 3);
        Assert.Equal(3, outra.Goles);
    }

    [Fact]
    public void DesmarcarOPontoQueEncheuOCofrinhoDevolveOGole()
    {
        var (sala, ana, _) = Mesa(RitmoDaBebida.Devagar);
        Pegou(sala, ana, ana, 7);
        Assert.Equal(1, ana.Goles);

        sala.AlternarBebi(ana.Token, sala.Rodada!.Numero);

        Assert.Equal(0, ana.Goles);
        Assert.Equal(6, ana.Pontos);
        Assert.Equal(6, ana.Cofrinho);
        Assert.Empty(sala.Rodada.BebemAgora);
    }

    [Fact]
    public void QuemJogaSemAlcoolSoJuntaPontos()
    {
        var (sala, ana, bia) = Mesa(RitmoDaBebida.Raiz, biaSemAlcool: true);

        Pegou(sala, ana, bia, 3);

        Assert.Equal(3, bia.Pontos);
        Assert.Equal(0, bia.Goles);
        Assert.Empty(sala.Rodada!.BebemAgora);
    }

    [Fact]
    public void OTamanhoDoCofrinhoEhConfiguravelEMudaNoMeioDoJogo()
    {
        var (sala, ana, _) = Mesa(RitmoDaBebida.Devagar);
        var comCofrinhoDe3 = sala.Configuracao with { Cofrinho = 3 };

        sala.Configurar(ana.Token, comCofrinhoDe3);
        Assert.Equal(3, sala.Configuracao.PontosPorGole);
        Pegou(sala, ana, ana, 3);

        Assert.Equal(1, ana.Goles);
        Assert.Equal(0, ana.Cofrinho);
    }

    [Fact]
    public void CofrinhoQueJaPassouDoNovoTamanhoEnchenaProximaVez()
    {
        var (sala, ana, _) = Mesa(RitmoDaBebida.Devagar);
        Pegou(sala, ana, ana, 5);
        sala.Proxima(ana.Token, sala.Rodada!.Numero);

        sala.Configurar(ana.Token, sala.Configuracao with { Cofrinho = 2 });
        Pegou(sala, ana, ana, 1);

        Assert.Equal(1, ana.Goles);
        Assert.Equal(0, ana.Cofrinho);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(21)]
    public void CofrinhoForaDe1A20NaoVale(int tamanho)
    {
        var (sala, ana, _) = Mesa(RitmoDaBebida.Devagar);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => sala.Configurar(ana.Token, sala.Configuracao with { Cofrinho = tamanho }));
        Assert.Equal("O cofrinho vai de 1 a 20 pontos.", erro.Message);
    }
}
