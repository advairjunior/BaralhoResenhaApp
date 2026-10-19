using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Reação rápida na carta (😂 🔥 💀 😱): cada um tem uma por carta, todo mundo
/// vê a contagem, e a carta que mais rendeu vira a "carta da noite" no fim.
/// </summary>
public sealed class ReacoesTestes
{
    private static readonly ConfiguracaoDoJogo SoBebaSe =
        new(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], ZonaSegura: true);

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Beto, Jogador Caio)
    {
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se já dormiu no cinema."),
            new Carta("bs-2", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se já caiu da cadeira."),
            new Carta("bs-3", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se já perdeu o celular na festa."),
        ]), new Random(1));
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);
        sala.Configurar(ana.Token, SoBebaSe with { CartasNaManga = false });
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, beto, caio);
    }

    [Fact]
    public void CadaUmReageEATurmaVeAContagem()
    {
        var mesa = Montar();

        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "😂");
        mesa.Sala.Reagir(mesa.Beto.Token, mesa.Rodada, "😂");
        mesa.Sala.Reagir(mesa.Caio.Token, mesa.Rodada, "💀");

        var rodada = mesa.Sala.Visao(mesa.Caio.Token).Rodada!;
        Assert.Equal(2, rodada.Reacoes["😂"]);
        Assert.Equal(1, rodada.Reacoes["💀"]);
        Assert.Equal("💀", rodada.MinhaReacao);
    }

    [Fact]
    public void ReagirDeNovoTrocaOuDesfaz()
    {
        var mesa = Montar();

        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "😂");
        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "🔥");
        Assert.Equal(new Dictionary<string, int> { ["🔥"] = 1 }, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Reacoes);

        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "🔥");
        var rodada = mesa.Sala.Visao(mesa.Ana.Token).Rodada!;
        Assert.Empty(rodada.Reacoes);
        Assert.Null(rodada.MinhaReacao);
    }

    [Fact]
    public void SoValemAsReacoesDoBotao()
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "🍆"));

        Assert.Equal("Essa reação não existe.", erro.Message);
    }

    [Fact]
    public void ReacaoDeCartaQueJaPassouNaoConta()
    {
        var mesa = Montar();
        var anterior = mesa.Rodada;
        mesa.Sala.Proxima(mesa.Ana.Token, anterior);

        mesa.Sala.Reagir(mesa.Beto.Token, anterior, "😂");

        Assert.Empty(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Reacoes);
    }

    [Fact]
    public void ACartaQueMaisRendeuReacaoViraACartaDaNoite()
    {
        var mesa = Montar();
        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "🔥");
        mesa.Sala.Proxima(mesa.Ana.Token, mesa.Rodada);
        var campea = mesa.Sala.Rodada!.Texto;
        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "😂");
        mesa.Sala.Reagir(mesa.Beto.Token, mesa.Rodada, "😂");
        mesa.Sala.Reagir(mesa.Caio.Token, mesa.Rodada, "💀");
        mesa.Sala.Proxima(mesa.Ana.Token, mesa.Rodada);

        mesa.Sala.Encerrar(mesa.Ana.Token);

        var carta = mesa.Sala.Visao(mesa.Ana.Token).Resumo!.CartaDaNoite!;
        Assert.Equal(campea, carta.Texto);
        Assert.Equal(new Dictionary<string, int> { ["😂"] = 2, ["💀"] = 1 }, carta.Reacoes);
    }

    [Fact]
    public void UmaReacaoSoNaoFazCartaDaNoite()
    {
        var mesa = Montar();
        mesa.Sala.Reagir(mesa.Ana.Token, mesa.Rodada, "🔥");

        mesa.Sala.Encerrar(mesa.Ana.Token);

        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Resumo!.CartaDaNoite);
    }
}
