using BaralhoResenhaApp.Api.Dominio;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Passar a carta sozinho: quando todo mundo responde (ou marca "Pronto"),
/// a carta passa em 3 segundos, sem depender de quem criou a sala.
/// Qualquer um pode segurar.
/// </summary>
public sealed class PassarSozinhoTestes
{
    private static readonly Carta BebaSe = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos.");
    private static readonly Carta EuNunca = new("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca dormi no cinema.");
    private static readonly Carta Regra = new("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, "Proibido falar de trabalho.");

    private sealed record Mesa(Sala Sala, Jogador[] Todos, FakeTimeProvider Relogio)
    {
        public Jogador Ana => Todos[0];
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar(Carta carta, bool passarSozinho = true)
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(1), relogio);
        var todos = new[] { "Ana", "Beto", "Caio" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [carta.Modo], true,
            CartasNaManga: false, PassarSozinho: passarSozinho));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos, relogio);
    }

    [Fact]
    public void NoBebaSeQuandoTodosRespondemACartaPassaEm3Segundos()
    {
        var mesa = Montar(BebaSe);
        var primeira = mesa.Rodada;
        mesa.Sala.AlternarBebi(mesa.Ana.Token, primeira);
        mesa.Sala.MarcarPronto(mesa.Todos[1].Token, primeira);
        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);

        mesa.Sala.MarcarPronto(mesa.Todos[2].Token, primeira);
        Assert.Equal(3000, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
        Assert.Equal(3, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Prontos.Count);

        // Antes da hora, ninguém consegue adiantar.
        mesa.Relogio.Advance(TimeSpan.FromSeconds(1));
        mesa.Sala.PassarSozinho(mesa.Todos[1].Token, primeira);
        Assert.Equal(primeira, mesa.Rodada);

        mesa.Relogio.Advance(TimeSpan.FromSeconds(2));
        mesa.Sala.PassarSozinho(mesa.Todos[1].Token, primeira);
        Assert.Equal(primeira + 1, mesa.Rodada);

        // Os outros celulares chegam atrasados: não pula duas cartas.
        mesa.Sala.PassarSozinho(mesa.Todos[2].Token, primeira);
        Assert.Equal(primeira + 1, mesa.Rodada);
    }

    [Fact]
    public void NosJogosComRevelacaoOProntoSoValeDepoisDela()
    {
        var mesa = Montar(EuNunca);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.MarcarPronto(mesa.Ana.Token, mesa.Rodada));
        Assert.Equal("Responda a carta primeiro.", erro.Message);

        foreach (var jogador in mesa.Todos) mesa.Sala.Responder(jogador.Token, mesa.Rodada, Sala.RespostaNunca);
        foreach (var jogador in mesa.Todos) mesa.Sala.MarcarPronto(jogador.Token, mesa.Rodada);

        Assert.Equal(3000, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }

    [Fact]
    public void RegraRelampagoTodoMundoMarcaQueEntendeu()
    {
        var mesa = Montar(Regra);
        foreach (var jogador in mesa.Todos) mesa.Sala.MarcarPronto(jogador.Token, mesa.Rodada);

        Assert.NotNull(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }

    [Fact]
    public void QualquerUmSeguraEAiSoQuemCriouASalaPassa()
    {
        var mesa = Montar(BebaSe);
        var primeira = mesa.Rodada;
        foreach (var jogador in mesa.Todos) mesa.Sala.MarcarPronto(jogador.Token, primeira);

        mesa.Sala.Segurar(mesa.Todos[2].Token, primeira);
        var visao = mesa.Sala.Visao(mesa.Ana.Token).Rodada!;
        Assert.Null(visao.PassaEmMs);
        Assert.Equal("Caio", visao.SeguradaPor);

        mesa.Relogio.Advance(TimeSpan.FromSeconds(5));
        mesa.Sala.PassarSozinho(mesa.Todos[1].Token, primeira);
        Assert.Equal(primeira, mesa.Rodada);

        mesa.Sala.Proxima(mesa.Ana.Token, primeira);
        Assert.Equal(primeira + 1, mesa.Rodada);
    }

    [Fact]
    public void ComAOpcaoDesligadaNinguemPassaSozinho()
    {
        var mesa = Montar(BebaSe, passarSozinho: false);
        foreach (var jogador in mesa.Todos) mesa.Sala.MarcarPronto(jogador.Token, mesa.Rodada);

        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }

    [Fact]
    public void QuemSaiDaSalaNaoTravaAContagem()
    {
        var mesa = Montar(BebaSe);
        mesa.Sala.MarcarPronto(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.MarcarPronto(mesa.Todos[1].Token, mesa.Rodada);

        mesa.Sala.Sair(mesa.Todos[2].Token);

        Assert.Equal(3000, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }
}
