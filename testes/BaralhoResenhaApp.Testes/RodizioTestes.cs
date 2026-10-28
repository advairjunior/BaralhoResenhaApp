using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// O {jogador} da carta sai entre quem foi chamado menos vezes: ninguém repete
/// enquanto alguém ainda não foi chamado nesta volta da mesa.
/// </summary>
public sealed class RodizioTestes
{
    private static Baralho Tribunais(int quantidade) => new(Enumerable.Range(1, quantidade)
        .Select(i => new Carta($"tr-{i}", ModoDeJogo.Tribunal, NivelDaCarta.Leve, $"{{jogador}} carta {i}?"))
        .ToList());

    private static (Sala, Jogador[]) Montar(Baralho baralho, int semente, params string[] nomes)
    {
        var sala = new Sala("ABCD", baralho, new Random(semente));
        var todos = nomes.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Tribunal], ZonaSegura: true));
        sala.Comecar(todos[0].Token);
        return (sala, todos);
    }

    private static Guid Chamado(Sala sala) => sala.Rodada!.Alvo!.Value;

    private static void Passar(Sala sala, Jogador anfitriao) => sala.Proxima(anfitriao.Token, sala.Rodada!.Numero);

    [Theory]
    [InlineData(1)]
    [InlineData(7)]
    [InlineData(42)]
    public void CadaVoltaDaMesaChamaTodoMundoUmaVez(int semente)
    {
        var (sala, todos) = Montar(Tribunais(30), semente, "Ana", "Beto", "Caio", "Duda", "Edu");

        var chamados = new List<Guid> { Chamado(sala) };
        for (var i = 1; i < 15; i++)
        {
            Passar(sala, todos[0]);
            chamados.Add(Chamado(sala));
        }

        foreach (var volta in chamados.Chunk(todos.Length))
            Assert.Equal(todos.Select(j => j.Id).Order(), volta.Order());
    }

    [Fact]
    public void QuemChegaNoMeioEntraNaVoltaSemSerChamadoSemParar()
    {
        var (sala, todos) = Montar(Tribunais(30), 3, "Ana", "Beto", "Caio");
        for (var i = 1; i < 6; i++) Passar(sala, todos[0]);
        var atrasado = sala.Entrar("Duda", false);

        var chamados = new List<Guid>();
        for (var i = 0; i < 8; i++)
        {
            Passar(sala, todos[0]);
            chamados.Add(Chamado(sala));
        }

        Assert.InRange(chamados.Count(id => id == atrasado.Id), 1, 3);
    }

    [Fact]
    public void DueloChamaOsDoisMenosChamados()
    {
        var cartas = Enumerable.Range(1, 10)
            .Select(i => new Carta($"mp-{i}", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve,
                $"{{jogador}} contra {{jogador2}}, rodada {i}", Duelo: true))
            .ToList();
        var sala = new Sala("ABCD", new Baralho(cartas), new Random(5));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.MaisProvavel], ZonaSegura: true));
        sala.Comecar(todos[0].Token);

        var primeiro = sala.Rodada!.Duelistas;
        Passar(sala, todos[0]);
        var segundo = sala.Rodada!.Duelistas;

        Assert.Equal(todos.Select(j => j.Id).Order(), primeiro.Concat(segundo).Order());
    }
}
