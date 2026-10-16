using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// "Conta essa": Eu Nunca de coisa que acontece com todo mundo ("eu nunca
/// gritei dormindo"). Na revelação, cada um que já fez conta a sua, um de cada
/// vez, com a foto na tela e o "Contei".
/// </summary>
public sealed class ContaEssaTestes
{
    private static readonly Carta ContaEssa = new("en-c1", ModoDeJogo.EuNunca, NivelDaCarta.Leve,
        "Eu nunca gritei dormindo.", Conta: true);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Ana => Todos[0];
        public int Rodada => Sala.Rodada!.Numero;
        public Guid? DaVez => Sala.Pendentes(Sala.Rodada!)
            .FirstOrDefault(p => p.Motivo == MotivoPendente.Historia)?.JogadorId;
        public Jogador Quem(Guid? id) => Todos.Single(j => j.Id == id);
    }

    private static Mesa Revelada(Carta carta, params string[] respostas)
    {
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(4));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true));
        sala.Comecar(todos[0].Token);
        for (var i = 0; i < todos.Length; i++) sala.Responder(todos[i].Token, sala.Rodada!.Numero, respostas[i]);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void QuemJaFezContaUmDeCadaVez()
    {
        var mesa = Revelada(ContaEssa, "ja", "ja", "nunca", "ja");
        var revelacao = mesa.Sala.Rodada!.Revelacao!;

        Assert.Equal(3, revelacao.Contadores.Count);
        Assert.Equal(revelacao.JaFizeram.OrderBy(id => id), revelacao.Contadores.OrderBy(id => id));
        Assert.Null(revelacao.ContaAHistoria);

        // Só quem está na vez aparece como pendente: os outros esperam.
        Assert.Equal(revelacao.Contadores[0], mesa.DaVez);
        Assert.Single(mesa.Sala.Pendentes(mesa.Sala.Rodada), p => p.Motivo == MotivoPendente.Historia);

        mesa.Sala.MarcarPronto(mesa.Quem(revelacao.Contadores[0]).Token, mesa.Rodada);
        Assert.Equal(revelacao.Contadores[1], mesa.DaVez);

        // Quem criou a sala passa a vez de quem contou sem pegar o celular.
        mesa.Sala.ConfirmarHistoria(mesa.Ana.Token, mesa.Rodada, revelacao.Contadores[1]);
        Assert.Equal(revelacao.Contadores[2], mesa.DaVez);

        mesa.Sala.MarcarPronto(mesa.Quem(revelacao.Contadores[2]).Token, mesa.Rodada);
        Assert.Null(mesa.DaVez);
        Assert.All(revelacao.Contadores, id => Assert.Equal(1, mesa.Quem(id).Estatisticas.Historias));
    }

    [Fact]
    public void SoQuemCriouASalaConfirmaPorOutroESoQuemEstaNaVez()
    {
        var mesa = Revelada(ContaEssa, "ja", "ja", "ja", "nunca");
        var contadores = mesa.Sala.Rodada!.Revelacao!.Contadores;
        var outro = mesa.Todos.First(j => j != mesa.Ana && j.Id != mesa.DaVez);

        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.ConfirmarHistoria(outro.Token, mesa.Rodada, contadores[0]));
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.ConfirmarHistoria(mesa.Ana.Token, mesa.Rodada, contadores[1]));
        Assert.Equal($"Agora é a vez de {mesa.Quem(contadores[0]).Nome} contar.", erro.Message);
    }

    [Fact]
    public void EuNuncaComumContinuaComUmaHistoriaSo()
    {
        var mesa = Revelada(new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1"),
            "ja", "ja", "nunca", "nunca");

        Assert.Empty(mesa.Sala.Rodada!.Revelacao!.Contadores);
        Assert.Null(mesa.DaVez);
    }

    [Fact]
    public void TodoNivelTemCartaDeContaEssa()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Conta).ToList();

        Assert.All(cartas, c => Assert.Equal(ModoDeJogo.EuNunca, c.Modo));
        foreach (var nivel in Enum.GetValues<NivelDaCarta>())
            Assert.True(cartas.Count(c => c.Nivel == nivel) >= 8, $"{nivel} tem poucas cartas de conta essa");
    }
}
