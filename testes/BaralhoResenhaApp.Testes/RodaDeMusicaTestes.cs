using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Roda de Música: a carta dá o tema ("abertura de novela"), o app sorteia a
/// ordem e cada um canta na sua vez, com a foto na tela. Cantou, passa para o
/// próximo; travou, quem criou a sala marca e a pessoa leva o ponto.
/// </summary>
public sealed class RodaDeMusicaTestes
{
    private static readonly Carta Novela = new("mu-1", ModoDeJogo.Musica, NivelDaCarta.Leve,
        "Abertura de novela! {jogador} começa e a roda segue.");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Ana => Todos[0];
        public int Rodada => Sala.Rodada!.Numero;
        public Jogador Quem(Guid id) => Todos.Single(j => j.Id == id);
        public Guid? DaVez => Sala.Pendentes(Sala.Rodada!)
            .FirstOrDefault(p => p.Motivo == MotivoPendente.Cantar)?.JogadorId;
    }

    private static Mesa Montar()
    {
        var sala = new Sala("ABCD", new Baralho([Novela]), new Random(8));
        var todos = new[] { "Ana", "Beto", "Caio" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Musica], true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void OAppSorteiaAOrdemComQuemComecaNaCarta()
    {
        var mesa = Montar();
        var fila = mesa.Sala.Rodada!.Fila;

        Assert.Equal(3, fila.Distinct().Count());
        Assert.Equal($"Abertura de novela! {mesa.Quem(fila[0]).Nome} começa e a roda segue.", mesa.Sala.Rodada.Texto);
        Assert.False(mesa.Sala.Rodada.PedeResposta);
        Assert.Equal(fila[0], mesa.DaVez);
        Assert.Equal(fila, mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Fila);
    }

    [Fact]
    public void QuemCantouPassaAVezEQuemTravouLevaOPonto()
    {
        var mesa = Montar();
        var fila = mesa.Sala.Rodada!.Fila;

        mesa.Sala.MarcarPronto(mesa.Quem(fila[0]).Token, mesa.Rodada);
        Assert.Equal(fila[1], mesa.DaVez);

        mesa.Sala.MarcarTravou(mesa.Quem(fila[0]).Token, mesa.Rodada, fila[1]);
        Assert.Equal(1, mesa.Quem(fila[1]).Pontos);
        Assert.Equal([fila[1]], mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Travaram);

        // O travou de quem bebe vira pendência de beber; a roda segue no próximo.
        mesa.Sala.MarcarPronto(mesa.Quem(fila[1]).Token, mesa.Rodada);
        Assert.Equal(fila[2], mesa.DaVez);

        mesa.Sala.ConfirmarHistoria(mesa.Ana.Token, mesa.Rodada, fila[2]);
        Assert.Null(mesa.DaVez);
        Assert.NotNull(mesa.Sala.Rodada!.PassaEm);
    }

    [Fact]
    public void QualquerUmDaTurmaMarcaQueTravouMenosQuemEstaCantando()
    {
        var mesa = Montar();
        var fila = mesa.Sala.Rodada!.Fila;
        var cantando = mesa.Quem(fila[0]);
        var outro = mesa.Quem(fila[1]);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.MarcarTravou(cantando.Token, mesa.Rodada, cantando.Id));
        Assert.Equal("Quem está cantando não marca o próprio travou.", erro.Message);
        erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.MarcarTravou(mesa.Quem(fila[2]).Token, mesa.Rodada, fila[1]));
        Assert.Equal($"Agora é a vez de {cantando.Nome} cantar.", erro.Message);

        mesa.Sala.MarcarTravou(outro.Token, mesa.Rodada, fila[0]);
        Assert.Equal(fila[1], mesa.DaVez);
    }

    [Fact]
    public void BancoTemRodaDeMusicaComQuemComeca()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.Musica).ToList();

        Assert.True(cartas.Count >= 20, $"só {cartas.Count} cartas de música");
        Assert.All(cartas, c => Assert.Contains("{jogador}", c.Texto));
        Assert.Contains(cartas, c => c.Nivel == NivelDaCarta.Leve);
        Assert.Contains(cartas, c => c.Nivel == NivelDaCarta.Picante);
    }
}
