using Microsoft.Extensions.Time.Testing;
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

    /// <summary>O tempo passa e só os celulares de <paramref name="conectados"/> consultam a sala.</summary>
    private static void PassarTempo(Sala sala, FakeTimeProvider relogio, TimeSpan tempo, params Jogador[] conectados)
    {
        for (var passou = TimeSpan.Zero; passou < tempo; passou += TimeSpan.FromSeconds(5))
        {
            relogio.Advance(TimeSpan.FromSeconds(5));
            foreach (var jogador in conectados) sala.Visao(jogador.Token);
        }
    }

    private static (Sala, Jogador[], FakeTimeProvider) MontarComRelogio(int semente, params string[] nomes)
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", Tribunais(40), new Random(semente), relogio);
        var todos = nomes.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Tribunal], ZonaSegura: true));
        sala.Comecar(todos[0].Token);
        return (sala, todos, relogio);
    }

    [Theory]
    [InlineData(1)]
    [InlineData(7)]
    [InlineData(42)]
    public void QuemCaiuNaoEhChamadoAteVoltar(int semente)
    {
        var (sala, todos, relogio) = MontarComRelogio(semente, "Ana", "Beto", "Caio", "Duda");
        var caio = todos[2];
        var naMesa = todos.Where(j => j != caio).ToArray();
        PassarTempo(sala, relogio, Sala.TempoParaCair + TimeSpan.FromSeconds(5), naMesa);
        var chamadasAntes = caio.Chamadas;

        for (var i = 0; i < 9; i++)
        {
            Passar(sala, todos[0]);
            Assert.NotEqual(caio.Id, Chamado(sala));
        }
        Assert.Equal(chamadasAntes, caio.Chamadas);
    }

    [Fact]
    public void QuemVoltaEntraNaVoltaAtual()
    {
        var (sala, todos, relogio) = MontarComRelogio(3, "Ana", "Beto", "Caio", "Duda");
        var caio = todos[2];
        PassarTempo(sala, relogio, Sala.TempoParaCair + TimeSpan.FromSeconds(5), todos.Where(j => j != caio).ToArray());
        for (var i = 0; i < 4; i++) Passar(sala, todos[0]);

        sala.Visao(caio.Token);
        var chamados = new List<Guid>();
        for (var i = 0; i < 4; i++)
        {
            Passar(sala, todos[0]);
            chamados.Add(Chamado(sala));
        }

        Assert.Contains(caio.Id, chamados);
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
