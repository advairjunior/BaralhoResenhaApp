using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

public sealed class EsquentaETiraEssaTestes
{
    private const int PorNivel = ConfiguracaoDoJogo.CartasPorNivel;

    private static Baralho UmaDeCadaNivel(int porNivel = 30) => new([
        .. from nivel in Enum.GetValues<NivelDaCarta>()
           from i in Enumerable.Range(1, porNivel)
           select new Carta($"{nivel}-{i}", ModoDeJogo.EuNunca, nivel, $"Eu nunca {nivel} {i}")
    ]);

    private static (Sala Sala, Jogador Ana) Comecar(Baralho baralho, ConfiguracaoDoJogo configuracao)
    {
        var sala = new Sala("ABCD", baralho, new Random(3));
        var ana = sala.Entrar("Ana", false);
        sala.Entrar("Beto", false);
        sala.Configurar(ana.Token, configuracao);
        sala.Comecar(ana.Token);
        return (sala, ana);
    }

    private static List<Carta> Jogar(Sala sala, Jogador ana, int cartas)
    {
        var jogadas = new List<Carta> { sala.Rodada!.Carta };
        while (jogadas.Count < cartas)
        {
            sala.Proxima(ana.Token, sala.Rodada!.Numero);
            jogadas.Add(sala.Rodada.Carta);
        }
        return jogadas;
    }

    [Fact]
    public void EsquentaSobeUmNivelACadaOitoCartasAteOLimite()
    {
        var picante = new ConfiguracaoDoJogo(NivelDaCarta.Picante, [ModoDeJogo.EuNunca], true, Esquentar: true);

        Assert.Equal(NivelDaCarta.Leve, picante.NivelNaCarta(0));
        Assert.Equal(NivelDaCarta.Leve, picante.NivelNaCarta(PorNivel - 1));
        Assert.Equal(NivelDaCarta.Resenha, picante.NivelNaCarta(PorNivel));
        Assert.Equal(NivelDaCarta.Picante, picante.NivelNaCarta(PorNivel * 2));
        Assert.Equal(NivelDaCarta.Picante, picante.NivelNaCarta(500));
        Assert.Equal(NivelDaCarta.Picante, (picante with { Esquentar = false }).NivelNaCarta(0));
    }

    [Fact]
    public void ComEsquentaAsPrimeirasCartasSaoLevesEANoiteVaiEsquentando()
    {
        var (sala, ana) = Comecar(UmaDeCadaNivel(),
            new ConfiguracaoDoJogo(NivelDaCarta.Original, [ModoDeJogo.EuNunca], true, Esquentar: true));

        var cartas = Jogar(sala, ana, PorNivel * 5);

        for (var bloco = 0; bloco < 5; bloco++)
        {
            var doBloco = cartas.Skip(bloco * PorNivel).Take(PorNivel).ToList();
            var limite = (NivelDaCarta)Math.Min(bloco + 1, (int)NivelDaCarta.Original);
            Assert.All(doBloco, carta => Assert.True(carta.Nivel <= limite, $"{carta.Id} passou de {limite}"));
            Assert.Contains(doBloco, carta => carta.Nivel == limite);
            // Depois de esquentar, não volta para o começo: no máximo um nível abaixo.
            Assert.All(doBloco, carta => Assert.True(carta.Nivel >= limite - 1, $"{carta.Id} esfriou demais"));
        }
    }

    [Fact]
    public void VisaoMostraQuandoSobeEAvisaNaPrimeiraCartaDoNivelNovo()
    {
        var (sala, ana) = Comecar(UmaDeCadaNivel(),
            new ConfiguracaoDoJogo(NivelDaCarta.Resenha, [ModoDeJogo.EuNunca], true, Esquentar: true));

        Assert.Equal(new EsquentaVisivel(NivelDaCarta.Leve, NivelDaCarta.Resenha, PorNivel, false),
            sala.Visao(ana.Token).Esquenta);
        Jogar(sala, ana, PorNivel);
        Assert.Equal(1, sala.Visao(ana.Token).Esquenta!.SobeEm);

        sala.Proxima(ana.Token, sala.Rodada!.Numero);
        Assert.Equal(new EsquentaVisivel(NivelDaCarta.Resenha, NivelDaCarta.Resenha, null, true),
            sala.Visao(ana.Token).Esquenta);
    }

    [Fact]
    public void SemEsquentaNaoTemFaixaDeEsquenta()
    {
        var (sala, ana) = Comecar(UmaDeCadaNivel(),
            new ConfiguracaoDoJogo(NivelDaCarta.Resenha, [ModoDeJogo.EuNunca], true));

        Assert.Null(sala.Visao(ana.Token).Esquenta);
    }

    [Fact]
    public void CartaTiradaNaoVoltaNaNoiteEQuemTirouApareceNaSeguinte()
    {
        var (sala, ana) = Comecar(UmaDeCadaNivel(porNivel: 2),
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true));
        var tirada = sala.Rodada!.Carta.Id;

        sala.Tirar(ana.Token, sala.Rodada.Numero);

        Assert.Equal("Ana", sala.Visao(ana.Token).CartaTiradaPor);
        Assert.Equal(1, ana.Estatisticas.Tiradas);
        var depois = Jogar(sala, ana, 12);
        Assert.DoesNotContain(depois, carta => carta.Id == tirada);
        Assert.Null(sala.Visao(ana.Token).CartaTiradaPor);
    }

    [Fact]
    public void DoisToquesEmTiraEssaTiramSoUmaCarta()
    {
        var (sala, ana) = Comecar(UmaDeCadaNivel(),
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true));
        var rodada = sala.Rodada!.Numero;

        sala.Tirar(ana.Token, rodada);
        sala.Tirar(ana.Token, rodada);

        Assert.Equal(rodada + 1, sala.Rodada!.Numero);
        Assert.Equal(1, ana.Estatisticas.Tiradas);
    }

    [Fact]
    public void TirarARegraRelampagoCancelaARegra()
    {
        var (sala, ana) = Comecar(new Baralho([
                new Carta("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, "Proibido falar tipo"),
                new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se"),
            ]),
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.RegraRelampago], true));
        Assert.NotNull(sala.Regra);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], true));

        sala.Tirar(ana.Token, sala.Rodada!.Numero);

        Assert.Null(sala.Regra);
    }

    [Fact]
    public void QuemTiraMuitasCartasViraFiscalDaResenha()
    {
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana" };
        ana.Estatisticas.Tiradas = 3;

        var fiscal = Assert.Single(PremiosDaNoite.Calcular([ana], []));

        Assert.Equal("Fiscal da resenha", fiscal.Titulo);
        Assert.Equal("Tirou 3 cartas do baralho", fiscal.Descricao);
    }
}
