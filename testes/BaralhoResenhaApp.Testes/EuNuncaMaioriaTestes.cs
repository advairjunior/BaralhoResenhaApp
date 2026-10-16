using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Eu Nunca com virada: se todo mundo já fez, ninguém leva; se a maioria já
/// fez, quem leva é a minoria que nunca fez.
/// </summary>
public sealed class EuNuncaMaioriaTestes
{
    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;

        public Revelacao Responder(params string[] respostas)
        {
            foreach (var (jogador, resposta) in Todos.Zip(respostas)) Sala.Responder(jogador.Token, Rodada, resposta);
            return Sala.Rodada!.Revelacao!;
        }
    }

    private static Mesa Montar(int pessoas)
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca dormi numa reunião de trabalho."),
        ]), new Random(1));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda", "Edu" }.Take(pessoas).Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true,
            Ritmo: RitmoDaBebida.Raiz, CartasNaManga: false));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void SeTodoMundoJaFezNinguemLeva()
    {
        var mesa = Montar(3);

        var revelacao = mesa.Responder(Sala.RespostaJa, Sala.RespostaJa, Sala.RespostaJa);

        Assert.Empty(revelacao.Perderam);
        Assert.Equal(3, revelacao.JaFizeram.Count);
        Assert.All(mesa.Todos, j => Assert.Equal(0, j.Pontos));
    }

    [Fact]
    public void SeAMaioriaJaFezQuemNuncaFezLeva()
    {
        var mesa = Montar(4);

        var revelacao = mesa.Responder(Sala.RespostaJa, Sala.RespostaJa, Sala.RespostaJa, Sala.RespostaNunca);

        Assert.True(revelacao.MinoriaLeva);
        Assert.Equal([mesa.Todos[3].Id], revelacao.Perderam);
        Assert.Equal(1, mesa.Todos[3].Pontos);
        Assert.Equal(0, mesa.Todos[0].Pontos);
        Assert.Null(revelacao.ContaAHistoria);
    }

    [Fact]
    public void SeAMinoriaJaFezQuemJaFezLevaComoSempre()
    {
        var mesa = Montar(5);

        var revelacao = mesa.Responder(Sala.RespostaJa, Sala.RespostaJa, Sala.RespostaNunca, Sala.RespostaNunca, Sala.RespostaNunca);

        Assert.False(revelacao.MinoriaLeva);
        Assert.Equal([mesa.Todos[0].Id, mesa.Todos[1].Id], revelacao.Perderam.Order());
    }

    [Fact]
    public void NoEmpateQuemJaFezLeva()
    {
        var mesa = Montar(4);

        var revelacao = mesa.Responder(Sala.RespostaJa, Sala.RespostaJa, Sala.RespostaNunca, Sala.RespostaNunca);

        Assert.False(revelacao.MinoriaLeva);
        Assert.Equal(2, revelacao.Perderam.Count);
        Assert.All(revelacao.Perderam, id => Assert.Contains(id, revelacao.JaFizeram));
    }

    [Fact]
    public void SoUmaPessoaFezAindaContaAHistoria()
    {
        var mesa = Montar(3);

        var revelacao = mesa.Responder(Sala.RespostaJa, Sala.RespostaNunca, Sala.RespostaNunca);

        Assert.Equal(mesa.Todos[0].Id, revelacao.ContaAHistoria);
        Assert.Equal([mesa.Todos[0].Id], revelacao.Perderam);
    }
}
