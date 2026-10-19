using BaralhoResenhaApp.Api.Dominio;
using Microsoft.Extensions.Time.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Quem caiu da sala não trava a mesa: a turma vê quem está sem conexão, a carta
/// revela e passa sem esperar por ela, e quem criou a sala pode tirá-la de vez.
/// </summary>
public sealed class QuemCaiuDaSalaTestes
{
    private static readonly Carta EuNunca = new("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca dormi no cinema.");
    private static readonly Carta BebaSe = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos.");

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Beto, Jogador Caio, FakeTimeProvider Relogio)
    {
        public int Rodada => Sala.Rodada!.Numero;

        /// <summary>O tempo passa e só os celulares de <paramref name="conectados"/> continuam consultando a sala.</summary>
        public void Passar(TimeSpan tempo, params Jogador[] conectados)
        {
            var passo = TimeSpan.FromSeconds(5);
            for (var passou = TimeSpan.Zero; passou < tempo; passou += passo)
            {
                Relogio.Advance(passo);
                foreach (var jogador in conectados) Sala.Visao(jogador.Token);
            }
        }
    }

    private static Mesa Montar(Carta carta, RitmoDaBebida ritmo = RitmoDaBebida.Devagar)
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(1), relogio);
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [carta.Modo], true,
            Ritmo: ritmo, CartasNaManga: false));
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, beto, caio, relogio);
    }

    private static bool Conectado(Sala sala, Jogador quemVe, Jogador quem) =>
        sala.Visao(quemVe.Token).Jogadores.Single(j => j.Id == quem.Id).Conectado;

    [Fact]
    public void ATurmaVeQuemFicouSemConexao()
    {
        var mesa = Montar(EuNunca);
        Assert.True(Conectado(mesa.Sala, mesa.Ana, mesa.Caio));

        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);

        Assert.False(Conectado(mesa.Sala, mesa.Ana, mesa.Caio));
        Assert.True(Conectado(mesa.Sala, mesa.Ana, mesa.Beto));
    }

    [Fact]
    public void QuemVoltaApareceConectadoDeNovo()
    {
        var mesa = Montar(EuNunca);
        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);

        var voltou = mesa.Sala.Entrar("Caio", false);

        Assert.True(Conectado(mesa.Sala, mesa.Ana, voltou));
    }

    [Fact]
    public void ACartaRevelaSemEsperarQuemCaiu()
    {
        var mesa = Montar(EuNunca);
        mesa.Sala.Responder(mesa.Ana.Token, mesa.Rodada, Sala.RespostaNunca);
        mesa.Sala.Responder(mesa.Beto.Token, mesa.Rodada, Sala.RespostaNunca);

        mesa.Passar(Sala.TempoParaCair - TimeSpan.FromSeconds(10), mesa.Ana, mesa.Beto);
        Assert.False(mesa.Sala.ConferirQuemCaiu());
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);

        mesa.Passar(TimeSpan.FromSeconds(10), mesa.Ana, mesa.Beto);
        Assert.True(mesa.Sala.ConferirQuemCaiu());
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);

        // Nada mudou desde a última conferência: não avisa a sala de novo.
        Assert.False(mesa.Sala.ConferirQuemCaiu());
    }

    [Fact]
    public void ACartaPassaSozinhaSemOProntoDeQuemCaiu()
    {
        var mesa = Montar(BebaSe);
        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);
        mesa.Sala.ConferirQuemCaiu();

        mesa.Sala.MarcarPronto(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.MarcarPronto(mesa.Beto.Token, mesa.Rodada);

        Assert.NotNull(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }

    [Fact]
    public void GoleDeQuemCaiuNaoSeguraACarta()
    {
        var mesa = Montar(BebaSe, RitmoDaBebida.Raiz);
        mesa.Sala.AlternarBebi(mesa.Caio.Token, mesa.Rodada);
        mesa.Sala.MarcarPronto(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.MarcarPronto(mesa.Beto.Token, mesa.Rodada);
        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);

        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);
        mesa.Sala.ConferirQuemCaiu();

        Assert.NotNull(mesa.Sala.Visao(mesa.Ana.Token).Rodada!.PassaEmMs);
    }

    [Fact]
    public void QuemCriouASalaTiraQuemCaiu()
    {
        var mesa = Montar(EuNunca);
        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);

        mesa.Sala.TirarDaSala(mesa.Ana.Token, mesa.Caio.Id);

        Assert.DoesNotContain(mesa.Sala.Jogadores, j => j.Id == mesa.Caio.Id);
        Assert.Throws<JogadorNaoReconhecidoException>(() => mesa.Sala.Visao(mesa.Caio.Token));
    }

    [Fact]
    public void SoQuemCriouASalaTiraAlguem()
    {
        var mesa = Montar(EuNunca);
        mesa.Passar(Sala.TempoParaCair, mesa.Ana, mesa.Beto);

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.TirarDaSala(mesa.Beto.Token, mesa.Caio.Id));
        Assert.Equal(3, mesa.Sala.Jogadores.Count);
    }

    [Fact]
    public void QuemEstaConectadoNaoPodeSerTirado()
    {
        var mesa = Montar(EuNunca);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.TirarDaSala(mesa.Ana.Token, mesa.Caio.Id));

        Assert.Equal("Caio ainda está conectado(a).", erro.Message);
        Assert.Equal(3, mesa.Sala.Jogadores.Count);
    }
}
