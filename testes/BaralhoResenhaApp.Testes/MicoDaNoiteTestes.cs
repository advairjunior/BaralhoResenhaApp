using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🤡 Mico da noite: na sala sem álcool, quem fechou a noite com mais pontos
/// paga um mico. A turma escolhe qual, numa votação entre três.
/// </summary>
public sealed class MicoDaNoiteTestes
{
    private static readonly Prendas Banco = new(
        Leve: ["Imite alguém da mesa."], Resenha: [], Picante: [],
        Micos: ["Cante o hino do seu time.", "Dance sem música por 20 segundos.", "Declame um poema para a mesa.",
            "Faça um desfile de moda."]);

    private static readonly Carta Oculos = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Pega quem usa óculos.");

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Bia, Jogador Caio)
    {
        public void Pegou(Jogador quem)
        {
            Sala.AlternarBebi(quem.Token, Sala.Rodada!.Numero);
            Sala.Proxima(Ana.Token, Sala.Rodada.Numero);
        }

        public MicoVisivel? Mico(Jogador quem) => Sala.Visao(quem.Token).Mico;
    }

    private static Mesa Montar(bool semAlcool = true)
    {
        var sala = new Sala("ABCD", new Baralho([Oculos], prendas: Banco), new Random(3));
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", false);
        var caio = sala.Entrar("Caio", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], true, SemAlcool: semAlcool));
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, bia, caio);
    }

    [Fact]
    public void NoFimQuemTemMaisPontosPagaUmDosTresMicos()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Pegou(mesa.Bia);
        mesa.Pegou(mesa.Caio);

        mesa.Sala.Encerrar(mesa.Ana.Token);

        var mico = mesa.Mico(mesa.Ana)!;
        Assert.Equal([mesa.Bia.Id], mico.Pagadores);
        Assert.Equal(3, mico.Opcoes.Count);
        Assert.Subset(Banco.Micos.ToHashSet(), mico.Opcoes.ToHashSet());
        Assert.Null(mico.Escolhido);
        Assert.Equal(2, mico.Eleitores);
    }

    [Fact]
    public void EmpateNoTopoPagamJuntos()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Pegou(mesa.Caio);

        mesa.Sala.Encerrar(mesa.Ana.Token);

        Assert.Equal([mesa.Bia.Id, mesa.Caio.Id], mesa.Mico(mesa.Ana)!.Pagadores.Order());
    }

    [Fact]
    public void ComAlcoolOuSemPontoNinguemPagaMico()
    {
        var comAlcool = Montar(semAlcool: false);
        comAlcool.Pegou(comAlcool.Bia);
        comAlcool.Sala.Encerrar(comAlcool.Ana.Token);
        Assert.Null(comAlcool.Mico(comAlcool.Ana));

        var semPontos = Montar();
        semPontos.Sala.Encerrar(semPontos.Ana.Token);
        Assert.Null(semPontos.Mico(semPontos.Ana));
    }

    [Fact]
    public void QuemPagaNaoVotaENaoVeOPlacarAntesDoFim()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.VotarNoMico(mesa.Bia.Token, 0));
        Assert.Equal("Quem paga o mico não vota.", erro.Message);
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.VotarNoMico(mesa.Ana.Token, 3));

        mesa.Sala.VotarNoMico(mesa.Ana.Token, 1);

        var daAna = mesa.Mico(mesa.Ana)!;
        Assert.Equal(1, daAna.MeuVoto);
        Assert.Equal(1, daAna.Votaram);
        // Ninguém vê como está a votação até todo mundo votar.
        Assert.Empty(daAna.Votos);
        Assert.Null(daAna.Escolhido);
    }

    [Fact]
    public void QuandoTodosVotamOMaisVotadoEhOMico()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        mesa.Sala.VotarNoMico(mesa.Ana.Token, 0);
        mesa.Sala.VotarNoMico(mesa.Ana.Token, 2);
        mesa.Sala.VotarNoMico(mesa.Caio.Token, 2);

        var mico = mesa.Mico(mesa.Bia)!;
        Assert.Equal(2, mico.Escolhido);
        Assert.Equal([0, 0, 2], mico.Votos);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.VotarNoMico(mesa.Caio.Token, 0));
        Assert.Equal("A turma já escolheu o mico.", erro.Message);
    }

    [Fact]
    public void EmpateNaVotacaoDecideNaSorte()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        mesa.Sala.VotarNoMico(mesa.Ana.Token, 0);
        mesa.Sala.VotarNoMico(mesa.Caio.Token, 1);

        Assert.Contains(mesa.Mico(mesa.Ana)!.Escolhido, new int?[] { 0, 1 });
    }

    [Fact]
    public void SeTodoMundoPagaOMicoSaiNaSorte()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Ana);
        mesa.Pegou(mesa.Bia);
        mesa.Pegou(mesa.Caio);

        mesa.Sala.Encerrar(mesa.Ana.Token);

        var mico = mesa.Mico(mesa.Ana)!;
        Assert.Equal(3, mico.Pagadores.Count);
        Assert.NotNull(mico.Escolhido);
    }

    [Fact]
    public void SoMaisUmaApagaOMicoEONovoFimSorteiaDeNovo()
    {
        var mesa = Montar();
        mesa.Pegou(mesa.Bia);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        mesa.Sala.Retomar(mesa.Ana.Token);
        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Mico);
        mesa.Pegou(mesa.Caio);
        mesa.Pegou(mesa.Caio);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        Assert.Equal([mesa.Caio.Id], mesa.Mico(mesa.Ana)!.Pagadores);
    }
}
